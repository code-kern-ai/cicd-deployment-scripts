import os
import json

from pathlib import Path
from tfparse import load_from_path


BASE_DIR = Path("/Users/andhrelja/DevOps/Infrastructure")
TF_DIR = "tf-azure-fnapp-github-runner-monitor"
os.makedirs(BASE_DIR / TF_DIR / "docs", exist_ok=True)

DOCS_HEADER = """
# Azure {resource_type}

Default location: {location}
Default resource group: {resource_group_name}
"""

DOCS_BODY = """
### {resource_name}

Docs: [Azure {resource_name}](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/{resource_type}/{resource_name_fmt})

```hcl
{resource} {path} {{
name                = "{name}"
resource_group_name = "{resource_group_name}"
{kwargs}
}}
```
"""

# Load all TF files from the given path
parsed = load_from_path(
    BASE_DIR / TF_DIR,
    vars_paths=("vars-prod.tfvars",),  # "vars-prod.tfvars"
)

resource_group = {
    "location": "northeurope",
    **next(
        filter(
            lambda x: x["__tfmeta"]["path"] == "data.azurerm_resource_group.this",
            parsed["azurerm_resource_group"],
        )
    ),
}

resources = {
    key: list(
        filter(
            lambda x: x["__tfmeta"].get("type") == "resource",
            parsed[key],
        )
    )
    for key in parsed.keys()
}

data_sources = {
    key: list(
        filter(
            lambda x: x["__tfmeta"].get("type") == "data",
            parsed[key],
        )
    )
    for key in parsed.keys()
}

variables = {
    key: list(
        filter(
            lambda x: x["__tfmeta"].get("type") is None,
            parsed[key],
        )
    )
    for key in parsed.keys()
}


def rm__attr(obj, attr):
    if type(obj) is str or obj is None:
        return obj
    if attr in obj.keys():
        obj.pop(attr)

    for key in obj.keys():
        if type(obj[key]) is dict:
            rm__attr(obj[key], attr)
        if type(obj[key]) is list:
            for item in obj[key]:
                if type(item) is dict:
                    rm__attr(item, attr)
    return obj


def generate_resource_docs(resources, resource_group, resource_type):
    resource_docs = DOCS_HEADER.format(
        location=resource_group["location"],
        resource_group_name=resource_group["name"],
        resource_type=resource_type.replace("-", " ").title(),
    )

    for resource_name, objs in resources.items():
        for obj in objs:
            obj["path"] = obj["__tfmeta"]["path"]
            rm__attr(obj, "__tfmeta")
            rm__attr(obj, "id")
            rm__attr(obj, "__ref__")

            if "resource_group_name" not in obj.keys():
                obj["resource_group_name"] = resource_group["name"]
            if "body" in obj.keys():
                obj["body"] = json.dumps(json.loads(obj["body"]), indent=2)
            for key in obj.keys():
                if type(obj[key]) is dict and "__attribute__" in obj[key].keys():
                    obj[key] = obj[key]["__attribute__"]
                if type(obj[key]) in [list, dict]:
                    obj[key] = json.dumps(obj[key], indent=2)

            fmt_kwargs = dict(
                resource=resource_type.replace("data-sources", "data"),
                resource_type=resource_type,
                resource_name=resource_name,
                resource_name_fmt=resource_name.replace("azurerm_", ""),
                path=obj.pop("path"),
                resource_group_name=obj.pop("resource_group_name"),
                kwargs="\n".join(
                    [f'{k}\t= "{v}"' for k, v in filter(None, obj.items())]
                ),
            )

            resource_docs += DOCS_BODY.format(
                name=obj.pop("name") if "name" in obj.keys() else fmt_kwargs["path"],
                **fmt_kwargs,
            )

    with open(BASE_DIR / TF_DIR / "docs" / f"{resource_type}.md", "w") as f:
        f.write(resource_docs)


generate_resource_docs(resources, resource_group, "resources")
generate_resource_docs(data_sources, resource_group, "data-sources")
generate_resource_docs(variables, resource_group, "variables")
