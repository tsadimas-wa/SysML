## Tool Comparison

| | SysML v2.0 Language Support (VS Code) | CATIA Magic / Cameo SysML v2 Community Edition | Syson | SysML v2 Release + SysML v2 API Services |
|---|---|---|---|---|
| **Type** | Editor extension | Desktop modeling tool (commercial vendor) | Web-based modeling tool (open source) | Reference implementation (Jupyter kernel + REST API server) |
| **Cost** | Free | Free (Community Mode licence) | Free | Free, open source |
| **Main purpose** | Viewing and editing `.sysml` files in VS Code | Learning and teaching SysML v2 | Graphical modeling | Writing, parsing and storing SysML v2 models |
| **Textual notation** | Yes (highlighting, auto-complete, formatting) | Yes, synchronised with diagrams | Limited text editor | Full textual notation (pilot implementation of the OMG spec) |
| **Graphical diagrams** | Diagram views (General, Interconnection, Action Flow, State, ...) | Yes | Yes | Basic visualisation (`%viz` in Jupyter) |
| **Model validation / parsing** | Real-time validation | Yes | Yes | Yes, reference parser |
| **Model repository / REST API** | No | No | No | Yes, local PostgreSQL + REST API (JSON elements) |
| **Model size limit** | None | **500 major elements** | None | None |
| **Main limitation** | File viewer/editor only: no model repository, no API, no publishing | Element cap; intended for learning and teaching, not production work | Text editing is limited | Manual setup (Docker, JDK 11 + Java 21, sbt, Miniconda/Jupyter); see [README.md](README.md) |
| **Recommended for this course** | Reading example files | Small exercises with diagrams | Graphical exploration | ✅ **Most reliable free option** |

**Summary:**
- **VS Code extension:** for viewing and editing `.sysml` files. It cannot store or share models.
- **CATIA Community Edition:** full-featured, but capped at 500 major elements ([Dassault Systèmes](https://discover.3ds.com/free-catia-sysmlv2-community-edition), [documentation](https://docs.nomagic.com/SYSML2P/2026x/catia-magic-cameo-sysml-v2-community-edition-286557495.html)).
- **Syson:** graphical tool with a limited text editor.
- **SysML v2 Release + API Services:** the most reliable free setup, with no size limits, full textual notation and programmatic access to the model as JSON. Setup is described in [README.md](README.md).

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

Syson is an open-source, web-based graphical modeling tool for SysML v2. Its text editor is limited.

### SysML v2 Resources

- [SysML v2 Release](https://github.com/Systems-Modeling/SysML-v2-Release)
- [SysML v2 API Services](https://github.com/Systems-Modeling/SysML-v2-API-Services)
