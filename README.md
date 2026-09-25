# SysML v2 Local Environment Setup Guide

This guide shows how to set up a fully local SysML v2 environment:
* **JupyterLab** with the SysML v2 kernel (from `SysML-v2-Release`) for writing and visualising models.
* A local **REST API** (`SysML-v2-API-Services`) backed by **PostgreSQL**, which stores the published models. You can query every model element as JSON.

Nothing is sent to external servers.

### Overview

```text
 JupyterLab + SysML kernel  --%publish-->  API server (sbt, port 9000)  -->  PostgreSQL (Docker, port 5432)
        (Java 21)                                (Java 11)
```

You will need **three things running** at the same time:

| # | What | Where | Java |
|---|---|---|---|
| 1 | PostgreSQL container | Docker (runs in the background) | – |
| 2 | API server (`sbt run`) | Terminal A | **JDK 11** |
| 3 | JupyterLab (`jupyter lab`) | Terminal B | **Java 21+** |

> ⚠️ The two components need **different Java versions**. The API Services require JDK 11 and the Jupyter kernel requires Java 21 or newer. Install both, and set `JAVA_HOME` to JDK 11 **only in the terminal that runs the API** (Part 1, step 5).

---

## Part 0: Install the Prerequisites

The commands below are for **Ubuntu/Debian**. Commands for **Arch Linux** are given where they differ. On Windows/macOS, use the linked installers.

### 1. Git
```bash
sudo apt install git            # Arch: sudo pacman -S git
```

### 2. Java (JDK 11 and Java 21)
```bash
sudo apt install openjdk-11-jdk openjdk-21-jdk     # Arch: sudo pacman -S jdk11-openjdk jdk21-openjdk
ls /usr/lib/jvm/                                   # note the installation folder names
```
Make **Java 21 the default** `java`. JupyterLab starts the kernel with whatever `java` is on your `PATH`.
```bash
sudo update-alternatives --config java             # Arch: sudo archlinux-java set java-21-openjdk
java -version                                      # should print 21.x
```
Windows/macOS: install [Temurin 11 and 21](https://adoptium.net/temurin/releases/).

### 3. sbt (Scala Build Tool)
The easiest cross-platform option is [SDKMAN](https://sdkman.io/):
```bash
curl -s "https://get.sdkman.io" | bash
source "$HOME/.sdkman/bin/sdkman-init.sh"
sdk install sbt
sbt --version
```
Arch: `sudo pacman -S sbt`. Other options: see [scala-sbt.org](https://www.scala-sbt.org/download/).

### 4. Docker
```bash
sudo apt install docker.io                # Arch: sudo pacman -S docker
sudo systemctl enable --now docker
sudo usermod -aG docker $USER             # log out and back in afterwards
docker run hello-world                    # test
```
Windows/macOS: install [Docker Desktop](https://www.docker.com/products/docker-desktop/).

### 5. Miniconda (Python 3)
```bash
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh    # accept the licence, keep the default location, answer "yes" to initialise
source ~/.bashrc                          # or open a new terminal (zsh users: ~/.zshrc)
conda --version
```
Windows/macOS: download the installer from [docs.conda.io](https://docs.conda.io/en/latest/miniconda.html). On Windows, tick **"Add Miniconda to my PATH"**.

Create a dedicated environment for this course and activate it:
```bash
conda create -n sysml python=3.11 -y
conda activate sysml
```
> Activate this environment (`conda activate sysml`) in every new terminal where you use Jupyter.

---

## Part 1: Backend API Setup (`SysML-v2-API-Services`)

### 1. Clone the Repository
```bash
git clone https://github.com/Systems-Modeling/SysML-v2-API-Services.git
cd SysML-v2-API-Services
```

### 2. Start the PostgreSQL Database
The API stores published models in a PostgreSQL database. Start one with Docker:
```bash
docker run -d \
  --name sysml2-postgres \
  -p 5432:5432 \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=sysml2 \
  postgres:13
```
You only need to create the container **once**. After a reboot, start it again with:
```bash
docker start sysml2-postgres
docker ps                        # sysml2-postgres should be listed as "Up"
```

### 3. Update the Hibernate Persistence Configuration
The repository's `persistence.xml` expects the password `mysecretpassword` and the host `localhost`. The container above uses the password `postgres`, so update the file to match. If you skip this step, the server fails with `ServiceException: Unable to create requested service [org.hibernate.engine.jdbc.env.spi.JdbcEnvironment]`.

1. Open `conf/META-INF/persistence.xml`.
2. Find the `<properties>` block at the bottom.
3. In `jdbc.url`, change `localhost` to `127.0.0.1` (this avoids an IPv6 localhost mismatch). Change the password from `mysecretpassword` to `postgres`.

```xml
<properties>
    <property name="javax.persistence.jdbc.driver" value="org.postgresql.Driver"/>
    <property name="javax.persistence.jdbc.url" value="jdbc:postgresql://127.0.0.1:5432/sysml2"/>
    <property name="javax.persistence.jdbc.user" value="postgres"/>
    <property name="javax.persistence.jdbc.password" value="postgres"/>
    <!-- Keep the rest as default -->
</properties>
```

### 4. (Recommended) Keep Your Data Between Restarts
By default, the same block contains:
```xml
<property name="hibernate.hbm2ddl.auto" value="create-drop"/>
```
With `create-drop`, **the database is emptied every time the API server stops**, so all published projects are lost. To keep them, change the value to `update`:
```xml
<property name="hibernate.hbm2ddl.auto" value="update"/>
```

### 5. Start the API Server (Terminal A)
In this terminal, switch to Java 11 and start the server with `sbt`:
```bash
# Ubuntu/Debian: /usr/lib/jvm/java-11-openjdk-amd64    Arch: /usr/lib/jvm/java-11-openjdk
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
export PATH=$JAVA_HOME/bin:$PATH
java -version                    # should print 11.x

sbt clean run
```
*The first run downloads dependencies and can take several minutes. Wait until the console shows `Listening for HTTP on /0:0:0:0:0:0:0:0:9000`.*

The server compiles on the **first HTTP request**. Open http://127.0.0.1:9000/projects in your browser and wait until it returns `[]` (an empty list). The Swagger API documentation is at http://127.0.0.1:9000/docs/.

**Keep this terminal open.** To stop the server, press `Enter` (or `Ctrl+C`).

---

## Part 2: Jupyter Frontend Setup (`SysML-v2-Release`) — Terminal B

Open a **new terminal** (Terminal B). Do **not** set `JAVA_HOME` to Java 11 here. `java -version` must print 21 or newer.

### 1. Clone the Repository & Install the Kernel
```bash
conda activate sysml
git clone https://github.com/Systems-Modeling/SysML-v2-Release.git
cd SysML-v2-Release/install/jupyter
chmod +x ./install.sh
./install.sh
```
The script (Windows: `install.bat`) installs the following into the active conda environment from `conda-forge`:
* `jupyter-sysml-kernel`
* JupyterLab 4
* Graphviz, which `%viz` needs
* Node.js

It also installs the JupyterLab SysML extension.

Check that the kernel was registered:
```bash
jupyter kernelspec list          # should list "sysml"
```

### 2. Fix the Kernel Configuration (Bypass Public Server)
By default, `%publish` sends models to a public test server. Point it at your local API instead by setting the `ISYSML_API_BASE_PATH` environment variable in the kernel's `kernel.json`.

1. Find the kernel location:
   ```bash
   jupyter kernelspec list
   ```
   Example output: `sysml   /home/<user>/miniconda3/envs/sysml/share/jupyter/kernels/sysml`
2. Open `kernel.json` in that folder:
   ```bash
   nano ~/miniconda3/envs/sysml/share/jupyter/kernels/sysml/kernel.json
   ```
3. **Keep the existing `argv` entries unchanged.** They contain the path to the kernel's `.jar` file. Add only the `"env"` block, and remember the comma after the previous entry:

```json
{
  "argv": [
    "java",
    "-jar",
    "<keep the existing path to jupyter-sysml-kernel-...jar>",
    "{connection_file}"
  ],
  "display_name": "SysML",
  "language": "sysml",
  "interrupt_mode": "message",
  "env": {
    "ISYSML_API_BASE_PATH": "http://127.0.0.1:9000"
  }
}
```

If `kernel.json` already has an `"env"` block, add the `ISYSML_API_BASE_PATH` line inside it instead of creating a second block.

> `install.sh` removes and recreates the kernel. If you run it again, repeat this step.

### 3. Start JupyterLab
```bash
conda activate sysml
mkdir -p ~/sysml-notebooks && cd ~/sysml-notebooks     # folder where your notebooks will be saved
jupyter lab
```
JupyterLab opens in your browser at http://localhost:8888. If it does not, copy the URL with the `?token=...` part from the terminal output. **Keep this terminal open.** Stop JupyterLab with `Ctrl+C` and confirm with `y`.

If you edit `kernel.json` while JupyterLab is running, restart the kernel (**Kernel → Restart Kernel**) so the change takes effect.

### Daily Start-Up Checklist
```bash
docker start sysml2-postgres                                  # 1. database
# Terminal A (Java 11):  export JAVA_HOME=<JDK 11 path> PATH=$JAVA_HOME/bin:$PATH
#                        cd SysML-v2-API-Services && sbt run  # 2. API, then open http://127.0.0.1:9000/projects
# Terminal B (Java 21):  conda activate sysml && jupyter lab  # 3. JupyterLab
```

---

## Part 3: Tutorial – Modeling and Publishing a Cost Model

This tutorial models the costs of a remote elderly monitoring system (REMS). The system has an ECG sensor (Shimmer3) and a data aggregator (Odroid XU4). The model covers:
* **Cost metadata:** capital (CapEx) and operating (OpEx) costs attached to parts.
* **A calculation:** total cost = CapEx + OpEx. In SysML v1 this was a ConstraintBlock with a parametric diagram.
* **A requirement:** the total cost must not exceed the budget.
* **The system architecture:** the patient's home with its sub-components.

> ⚠️ **Before you start:** complete [Part 2, step 2](#2-fix-the-kernel-configuration-bypass-public-server) (the `kernel.json` fix) and restart JupyterLab. Otherwise `%publish` sends your model to the public server instead of your local API. Also check that the API server from Part 1 is running (`http://127.0.0.1:9000/projects` should open in the browser).

Open JupyterLab and create a new notebook: **File → New → Notebook** and select the **SysML** kernel.

### 1. Define the Model (Cell 1)
Paste the following code into the first cell and run it with `Shift+Enter`:

```sysml
package REMS_Cost_Model {
    
    // ==========================================
    // 1. COST METADATA (Library)
    // ==========================================
    metadata def Cost {
        // Fully qualifying the data types bypasses the need for imports
        attribute value : ScalarValues::Real;
        attribute measUnit : ScalarValues::String;
        attribute instances : ScalarValues::Integer;
    }

    metadata def CapExCost :> Cost;
    metadata def OpExCost :> Cost;

    metadata def AcquisitionCost :> CapExCost;
    metadata def IntegrationCost :> CapExCost;

    metadata def EnergyCost :> OpExCost;
    metadata def LaborCost :> OpExCost;
    metadata def MaintenanceCost :> OpExCost;

    // ==========================================
    // 2. CALCULATIONS (Replaces SysML v1 ConstraintBlock)
    // ==========================================
    // Represents the 'CostComputationFunction' from the original model
    calc def CostComputationFunction {
        in capex : ScalarValues::Real;
        in opex : ScalarValues::Real;
        return totalCost : ScalarValues::Real = capex + opex;
    }

    // ==========================================
    // 3. REQUIREMENTS (Replaces SysML v1 QuantitativeReq)
    // ==========================================
    // Represents budgetary constraints evaluated against computed metrics
    requirement def QuantitativeReq {
        doc /* Ensure the evaluated total cost does not exceed the allowed budget */
        attribute maxBudget : ScalarValues::Real;
        attribute evaluatedCost : ScalarValues::Real;
        require constraint { evaluatedCost <= maxBudget }
    }

    // ==========================================
    // 4. SYSTEM ARCHITECTURE
    // ==========================================
    part def Shimmer3_ECG;
    part def Odroid_XU4;

    part def Elderly_Patient_Home {
        
        // System-level CapEx (e.g., Overall Installation)
        @CapExCost {
            value = 806.0;
            measUnit = "Euro";
            instances = 1;
        }

        // System-level OpEx (e.g., Annual IT Maintenance)
        @MaintenanceCost {
            value = 150.0;
            measUnit = "Euro";
            instances = 1;
        }

        // Execute the calculation block natively (Replaces Parametric Diagrams)
        attribute totalSystemCost : ScalarValues::Real = CostComputationFunction(
            capex = 806.0, 
            opex = 150.0
        );

        // Sub-component: Medical Sensor (with OpEx energy cost)
        part device : Shimmer3_ECG {
            @AcquisitionCost {
                value = 500.0;
                measUnit = "Euro";
                instances = 1;
            }
            // Applying OpEx to the edge device (e.g., charging/battery cost)
            @EnergyCost {
                value = 15.0; 
                measUnit = "Euro";
                instances = 1;
            }
        }
        
        // Sub-component: Data Aggregator (with OpEx energy cost)
        part dataAggregator : Odroid_XU4 {
            @AcquisitionCost {
                value = 80.0;
                measUnit = "Euro";
                instances = 1;
            }
            // Applying OpEx to the aggregator (e.g., continuous power consumption)
            @EnergyCost {
                value = 25.0; 
                measUnit = "Euro";
                instances = 1;
            }
        }

        // Bind the requirement and verify the constraint (Replaces 'satisfy' dependency arrows)
        satisfy requirement systemBudget : QuantitativeReq {
            maxBudget = 1000.0;
            evaluatedCost = totalSystemCost;
        }
    }
}
```

If the model parses without errors, the kernel lists the elements it created, for example `Package REMS_Cost_Model (...)`. If there is a syntax error, the kernel shows the line and column. Fix it and run the cell again.

#### How the model is built

| Section | SysML v2 construct | What it does |
|---|---|---|
| 1. Cost metadata | `metadata def`, `:>` (specialisation) | Defines a `Cost` annotation with `value`, `measUnit` and `instances`. `CapExCost` and `OpExCost` specialise it, and the concrete cost types (`AcquisitionCost`, `EnergyCost`, ...) specialise those. |
| 2. Calculation | `calc def` with `in` parameters and `return` | A reusable function: `totalCost = capex + opex`. |
| 3. Requirement | `requirement def` with `require constraint` | A budget check: `evaluatedCost <= maxBudget`. |
| 4. Architecture | `part def`, `part`, `@Metadata { ... }` | `Elderly_Patient_Home` contains a `device` and a `dataAggregator`. Each carries its cost annotations. |
| Binding | `attribute ... = CostComputationFunction(...)`, `satisfy requirement` | Computes `totalSystemCost` (806 + 150 = 956 €) and checks it against the 1000 € budget. |

Notes:
* Types are written with their full names (e.g. `ScalarValues::Real`), so the model needs no `import` statements.
* `@CapExCost { ... }` is shorthand for adding a metadata annotation with values to the element that contains it.

### 2. (Optional) Visualise the Model
In a new cell you can draw diagrams with the `%viz` magic command:

```sysml
%viz REMS_Cost_Model
```

To draw only the system architecture, pass the qualified name of the part definition:

```sysml
%viz REMS_Cost_Model::Elderly_Patient_Home
```

This draws `Elderly_Patient_Home` with its `device` and `dataAggregator` parts, the `totalSystemCost` attribute, and the `systemBudget` requirement it satisfies.

You can also pick a specific view, for example a tree view:

```sysml
%viz --view=tree REMS_Cost_Model::Elderly_Patient_Home
```

### 3. Publish to the Local API (Cell 2)
In a **new, separate cell**, run the `%publish` magic command. It sends the parsed model elements to your local API, which stores them in PostgreSQL:

```sysml
%publish REMS_Cost_Model
```

**Expected Output:**
```text
API base path: http://127.0.0.1:9000
Processing..
Posting commit. Additions: X, Deletions: 0, Modified elements: 0
Successfully posted commit: <COMMIT_ID> on branch: (main) <PROJECT_ID>
```

Copy `<PROJECT_ID>` and `<COMMIT_ID>`. You need them in Part 4.

**Troubleshooting:**
* **`API base path` shows a public URL, not `127.0.0.1:9000`:** the `kernel.json` fix was not applied. Edit the file again, then restart the kernel (**Kernel → Restart Kernel**) or JupyterLab.
* **`Connection refused`:** the API server (`sbt run`) is not running, or it has not finished starting yet.
* **`ERROR: ... not found`:** run Cell 1 first. The model must be loaded into the kernel before you can publish it.

---

## Part 4: Accessing the Model Through the API

The published model is now stored as JSON and can be queried over REST. Each SysML element (package, part, attribute, metadata usage, ...) is a separate JSON object with an `@id`, an `@type` and properties such as `declaredName`.

### 1. Browse the Endpoints
Open these URLs in your browser (Firefox formats JSON nicely) or query them with `curl`:

| What | Endpoint |
|---|---|
| All projects | `http://127.0.0.1:9000/projects` |
| One project | `http://127.0.0.1:9000/projects/<PROJECT_ID>` |
| Branches of a project | `http://127.0.0.1:9000/projects/<PROJECT_ID>/branches` |
| Commits of a project | `http://127.0.0.1:9000/projects/<PROJECT_ID>/commits` |
| All elements in a commit | `http://127.0.0.1:9000/projects/<PROJECT_ID>/commits/<COMMIT_ID>/elements` |
| Root elements only | `http://127.0.0.1:9000/projects/<PROJECT_ID>/commits/<COMMIT_ID>/roots` |
| A single element | `http://127.0.0.1:9000/projects/<PROJECT_ID>/commits/<COMMIT_ID>/elements/<ELEMENT_ID>` |

> **Pagination:** list endpoints return at most **100 items per page**. Add `?page[size]=1000` to get more at once, or follow the `Link: ...; rel="next"` response header to the next page. With `curl`, quote the URL or escape the brackets (`curl -g`).

Example with `curl` and `jq` (install `jq` with `sudo apt install jq` / `sudo pacman -S jq`):
```bash
curl -s http://127.0.0.1:9000/projects | jq '.[] | {name, "@id"}'
curl -sg "http://127.0.0.1:9000/projects/<PROJECT_ID>/commits/<COMMIT_ID>/elements?page[size]=1000" | jq 'length'
```

### 2. Query the Model with Python
Install `requests` in the course environment first:
```bash
conda activate sysml
pip install requests
```

The following script lists every named element in the published model by type. It follows the pagination links so that no elements are missed. Save it as `list_elements.py`, replace the two IDs, and run `python list_elements.py` in a terminal where `sysml` is activated:

```python
import requests

BASE = "http://127.0.0.1:9000"
PROJECT_ID = "<PROJECT_ID>"
COMMIT_ID = "<COMMIT_ID>"

elements = []
url = f"{BASE}/projects/{PROJECT_ID}/commits/{COMMIT_ID}/elements"
while url:
    r = requests.get(url)
    r.raise_for_status()
    elements.extend(r.json())
    url = r.links.get("next", {}).get("url")   # next page, if any

print(f"{len(elements)} elements")

for e in elements:
    name = e.get("declaredName")
    if name:
        print(f"{e['@type']:<25} {name}")
```

The output includes, for example, `PartDefinition Elderly_Patient_Home`, `PartUsage device`, `MetadataDefinition AcquisitionCost` and `RequirementDefinition QuantitativeReq`. You can process these elements further, for example to add up all cost annotations or to produce a cost report outside the modeling tool.

> **Note:** each `%publish` creates a new commit. If you change the model, run Cell 1 again and then `%publish` again, and use the new `<COMMIT_ID>`.
