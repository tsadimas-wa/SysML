# SysML v2 Local Environment Setup Guide

This guide outlines how to set up a completely local SysML v2 development environment using JupyterLab for modeling and a local PostgreSQL-backed REST API for querying the parsed abstract syntax tree (AST) elements as JSON.

## Prerequisites
* **Miniconda / Python 3.x** (for JupyterLab)
* **Docker** (for the PostgreSQL database)
* **JDK 11 & sbt** (Scala Build Tool, for the API server)
* **Git**

---

## Part 1: Backend API Setup (`SysML-v2-API-Services`)

### 1. Clone the Repository
```bash
git clone https://github.com/Systems-Modeling/SysML-v2-API-Services.git
cd SysML-v2-API-Services
```

### 2. Start the PostgreSQL Database
The API requires a PostgreSQL database to store the parsed models. Spin it up using Docker:
```bash
docker run -d \
  --name sysml2-postgres \
  -p 5432:5432 \
  -e POSTGRES_USER=postgres \
  -e POSTGRES_PASSWORD=postgres \
  -e POSTGRES_DB=sysml2 \
  postgres:13
```

### 3. Fix the Hibernate Persistence Configuration
By default, the API repository ships with an incorrect database password in its Hibernate configuration, which will cause a `ServiceException: Unable to create requested service [org.hibernate.engine.jdbc.env.spi.JdbcEnvironment]` error.

1. Open `conf/META-INF/persistence.xml`
2. Locate the `<properties>` block at the bottom.
3. Update the `jdbc.url` to use `127.0.0.1` (to avoid IPv6 localhost mismatch) and change the password from `mysecretpassword` to `postgres`.

```xml
<properties>
    <property name="javax.persistence.jdbc.driver" value="org.postgresql.Driver"/>
    <property name="javax.persistence.jdbc.url" value="jdbc:postgresql://127.0.0.1:5432/sysml2"/>
    <property name="javax.persistence.jdbc.user" value="postgres"/>
    <property name="javax.persistence.jdbc.password" value="postgres"/>
    <!-- Keep the rest as default -->
</properties>
```

### 4. Start the API Server
Ensure your terminal is using Java 11, then launch the server using `sbt`:
```bash
export JAVA_HOME=/usr/lib/jvm/java-11-openjdk
export PATH=$JAVA_HOME/bin:$PATH

sbt clean run
```
*Wait until the console displays `Listening for HTTP on /0:0:0:0:0:0:0:0:9000`.*

---

## Part 2: Jupyter Frontend Setup (`SysML-v2-Release`)

### 1. Clone the Repository & Install Kernel
```bash
git clone https://github.com/Systems-Modeling/SysML-v2-Release.git
cd SysML-v2-Release
```
*(Follow the standard instructions in this repository to install the Jupyter Kernel into your Miniconda environment, typically via `pip install .` inside the `jupyter` folder).*

### 2. Fix the Kernel Configuration (Bypass Public Server)
By default, the Jupyter kernel tries to publish models to the public Intercax test server. You must hardcode it to use your local API.

1. Find the kernel location:
   ```bash
   jupyter kernelspec list
   ```
2. Open the `kernel.json` file located in the `sysml` directory shown by the command above (e.g., `nano /path/to/share/jupyter/kernels/sysml/kernel.json`).
3. Add the `"env"` block pointing to `127.0.0.1:9000`:

```json
{
  "argv": [
    "java",
    "-jar",
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

### 3. Start JupyterLab
```bash
jupyter lab
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

Example with `curl` and `jq`:
```bash
curl -s http://127.0.0.1:9000/projects | jq '.[] | {name, "@id"}'
```

### 2. Query the Model with Python
The following script lists every named element in the published model by type:

```python
import requests

BASE = "http://127.0.0.1:9000"
PROJECT_ID = "<PROJECT_ID>"
COMMIT_ID = "<COMMIT_ID>"

elements = requests.get(
    f"{BASE}/projects/{PROJECT_ID}/commits/{COMMIT_ID}/elements"
).json()

for e in elements:
    name = e.get("declaredName")
    if name:
        print(f"{e['@type']:<25} {name}")
```

The output includes, for example, `PartDefinition Elderly_Patient_Home`, `PartUsage device`, `MetadataDefinition AcquisitionCost` and `RequirementDefinition QuantitativeReq`. You can process these elements further, for example to add up all cost annotations or to produce a cost report outside the modeling tool.

> **Note:** each `%publish` creates a new commit. If you change the model, run Cell 1 again and then `%publish` again, and use the new `<COMMIT_ID>`.
