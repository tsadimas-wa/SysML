## Tool Comparison

| | SysML v2.0 Language Support (VS Code) | CATIA Magic / Cameo SysML v2 Community Edition | Syson | Syside (Sensmetry) | SysML v2 Release + SysML v2 API Services |
|---|---|---|---|---|---|
| **Type** | Editor extension | Desktop modeling tool (commercial vendor) | Web-based modeling tool (open source, runs as a server) | VS Code extensions (Editor, Modeler) + Python library (Automator); commercial vendor | OMG pilot (reference) implementation: Jupyter kernel + REST API server |
| **Cost** | Free | Free (Community Mode licence) | Free, open source | Editor free for everyone. Modeler + Automator are paid, but **free with an Academic Licence** (students/teachers, non-commercial) | Free, open source |
| **Main purpose** | Viewing and editing `.sysml` files in VS Code | Learning and teaching SysML v2 | Graphical modeling | Text-first modeling with generated diagrams and Python automation | Writing, parsing and storing SysML v2 models |
| **Textual notation** | Yes (highlighting, auto-complete, formatting) | Yes, synchronised with diagrams | Limited: textual import works; textual export is incomplete | Yes, text is the primary notation (auto-complete, navigation, rename, formatting) | Full textual notation |
| **Graphical diagrams** | Diagram views (General, Interconnection, Action Flow, State, ...) | Yes | Yes | Modeler only: diagrams and grid views generated from the text and kept in sync; diagram export | Static, generated diagrams (`%viz`), not editable |
| **Model validation / parsing** | Real-time validation | Yes | Yes | Real-time validation | Yes, reference parser |
| **SysML v2 spec compliance¹** | No formal claim: advertises "complete SysML v2.0 support" and bundles the OMG standard library, but names no spec version and lists no limitations | Vendor claims 100% conformance with the OMG SysML v2 standard, with two-way text/diagram sync | Aims at full compliance; implements the OMG metamodel. Documented alignment with the Beta 2.3 metamodel and libraries; textual export and REST API are partial | Vendor states Modeler is tested against SysML 2.0 (release 2026-04); Sensmetry helped write the spec | **Reference:** pilot implementation built by the OMG submission team alongside the spec; ships the official standard libraries. Not a certified product |
| **Model repository / REST API** | No | Only through Teamwork Cloud (separate commercial server) | Yes, server database; partial support for the OMG SysML v2 REST API | No model server; models are `.sysml` files (e.g. in Git). Automator provides a Python API instead | Yes, local PostgreSQL + OMG SysML v2 REST API (pilot implementation) |
| **Model size limit** | None | **500 major elements** | None | None stated | None |
| **Main limitation** | File viewer/editor only: no model repository, no API, no publishing | Element cap; intended for learning and teaching, not production work | Text editing is limited; you must deploy a server (e.g. Docker) or use a hosted instance | Diagrams and Python API need a licence (the Academic Licence must be requested); proprietary | Manual setup (Docker, JDK 11 + Java 21, sbt, Miniconda/Jupyter); see [README.md](README.md) |
| **Recommended for this course** | Reading and editing example files | Small exercises with diagrams | Graphical exploration | Writing models in VS Code; scripted analysis with Python (Academic Licence) | ✅ **Reference implementation: most standard-compliant free option** |

¹ SysML v2.0 was formally adopted by the OMG in July 2025. There is no official conformance certification yet; the Systems Modeling Community (SMC) is still developing a conformance test suite. Commercial compliance entries are vendor claims.

**Summary:**
- **VS Code extension:** for viewing and editing `.sysml` files. It cannot store or share models.
- **CATIA Community Edition:** full textual and graphical modeling, but capped at 500 major elements. REST API access needs Teamwork Cloud ([Dassault Systèmes](https://discover.3ds.com/free-catia-sysmlv2-community-edition), [documentation](https://docs.nomagic.com/SYSML2P/2026x/catia-magic-cameo-sysml-v2-community-edition-286557495.html)).
- **Syside:** text-first modeling in VS Code. The free Editor has no diagrams; the Modeler (diagrams) and Automator (Python API) are free only with an Academic Licence ([pricing](https://sensmetry.com/syside-pricing/), [docs](https://docs.sensmetry.com/)).
- **Syson:** graphical web tool. It has a partial REST API but limited textual editing and export.
- **SysML v2 Release + API Services:** the most standard-compliant free setup, because it is the reference implementation. It has no size limits, supports the full textual notation and gives programmatic access to the model as JSON. It is a pilot rather than a polished product: setup takes effort and its diagrams are static. Setup is described in [README.md](README.md).

## SysML v2.0 Language Support for VS Code

1. Open VS Code.
2. Press `Ctrl+Shift+X` to open **Extensions**.
3. Search for **SysML v2.0 Language Support**.
4. Select the extension by **jamied**.
5. Click **Install**.
6. Reload VS Code if prompted.

Extension identifier: `jamied.sysml-v2-support`

## Tools

### CATIA Magic / Cameo SysML v2 Community Edition

Download it from [3DS software](https://software.3ds.com/). You need a free 3DS account.

The Community Edition is free and intended for learning and teaching. It can hold up to **500 major elements** per model. You must select **Use in Community Mode** in the License Manager. See the [official page](https://discover.3ds.com/free-catia-sysmlv2-community-edition).

### Syson

Syson is an open-source, web-based graphical modeling tool for SysML v2. It can import textual `.sysml` files, but its text editing is limited and textual export is not complete. It offers partial support for the OMG SysML v2 REST API. See the [SysON documentation](https://doc.mbse-syson.org/).

### Syside (Sensmetry)

Syside is a SysML v2 tool suite from Sensmetry. It treats the textual notation as the main way to model:
* **Syside Editor** (free VS Code extension): syntax highlighting, auto-completion, go to definition/references, rename, formatting and real-time validation.
* **Syside Modeler** (licensed VS Code extension): diagrams and grid views generated from the text and kept in sync, with diagram export.
* **Syside Automator** (licensed Python library): query and edit models, evaluate expressions, write custom validation rules, and generate reports.

Students and teachers can use all Syside tools for free for non-commercial, educational and research purposes. Request an **Academic Licence** with an educational e-mail address or proof of student status: [Syside pricing](https://sensmetry.com/syside-pricing/).

Install the Editor from the VS Code Extensions view by searching for **Syside**. Do not enable it together with the *SysML v2.0 Language Support* extension; two SysML language servers on the same files can give duplicate or conflicting diagnostics.

### SysML v2 Resources

- [SysML v2 Release](https://github.com/Systems-Modeling/SysML-v2-Release)
- [SysML v2 API Services](https://github.com/Systems-Modeling/SysML-v2-API-Services)
