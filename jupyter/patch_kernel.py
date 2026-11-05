import json, subprocess, sys
url = sys.argv[1]
out = json.loads(subprocess.check_output(["jupyter", "kernelspec", "list", "--json"]))
path = out["kernelspecs"]["sysml"]["resource_dir"] + "/kernel.json"
k = json.load(open(path))
k.setdefault("env", {})["ISYSML_API_BASE_PATH"] = url
json.dump(k, open(path, "w"), indent=2)
print("patched", path)
