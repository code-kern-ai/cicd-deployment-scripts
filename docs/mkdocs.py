import os
import yaml
import json

CICD_DEPLOYMENT_SCRIPTS_DIR = (
    "/Users/andhrelja/DevOps/Infrastructure/cicd-deployment-scripts"
)
GITHUB_ACTIONS_WORKFLOWS_DIR = os.path.join(
    CICD_DEPLOYMENT_SCRIPTS_DIR, ".github", "workflows"
)
DOCS_JSON_FILE = os.path.join(CICD_DEPLOYMENT_SCRIPTS_DIR, "docs", "docs.json")
DOCS_INPUT = os.path.join(
    CICD_DEPLOYMENT_SCRIPTS_DIR, "docs", "docs_input.json"
)
README_TEMPLATE = """
# cicd-deployment-scripts

Scripts used for Kern AI CI/CD efforts.

## Table of Contents

{toc}

## GitHub Actions

{gh_actions}
"""


with open(DOCS_INPUT, "r") as file:
    docs_manual = json.load(file)


def get_workflow_files():
    global docs_manual
    return [
        os.path.join(GITHUB_ACTIONS_WORKFLOWS_DIR, workflow_file)
        for workflow_file in docs_manual
    ]


def get_workflow_info(workflow_files):
    workflow_info = {}

    def steps_filter_criteria(x):
        return (
            "name" in x.keys()
            and "checkout" not in x.get("name").lower()
            and "azure login" not in x.get("name").lower()
            and "azure cloud login" not in x.get("name").lower()
            and "kubelogin" not in x.get("name").lower()
            and "github configuration" not in x.get("name").lower()
            and "clone cicd" not in x.get("name").lower()
            and "qemu" not in x.get("name").lower()
            and "set up docker" not in x.get("name").lower()
            and "log into" not in x.get("name").lower()
            and "env.image_tag" not in x.get("name").lower()
            and "env.kubernetes_cluster_repo_name" not in x.get("name").lower()
            and "setup opentofu" not in x.get("name").lower()
            and "publish opentofu" not in x.get("name").lower()
            and "download opentofu" not in x.get("name").lower()
            and "opentofu init" not in x.get("name").lower()
            and "setup python" not in x.get("name").lower()
        ) or (
            "name" not in x.keys()
            and "uses" in x.keys()
            and "aks-set-context" not in x.get("uses", "").lower()
        )

    for workflow_file in workflow_files:
        workflow_file_name = os.path.basename(workflow_file)
        with open(workflow_file, "r") as file:
            workflow = yaml.safe_load(file)

        workflow_info[workflow_file_name] = {
            "name": workflow["name"],
            "trigger": docs_manual.get(workflow_file_name, {}).get("trigger", ""),
            "inputs": list(
                workflow.get(True, {}).get("workflow_call", {}).get("inputs", {}).keys()
                if workflow.get(True, {}).get("workflow_call", {}) is not None
                else []
            ),
            "outputs": list(
                workflow.get(True, {})
                .get("workflow_call", {})
                .get("outputs", {})
                .keys()
                if workflow.get(True, {}).get("workflow_call", {}) is not None
                else []
            ),
            "description": docs_manual.get(workflow_file_name, {}).get(
                "description", ""
            ),
            "troubleshooting": docs_manual.get(workflow_file_name, {}).get(
                "troubleshooting", ""
            ),
            "jobs": [],
        }
        workflow_info[workflow_file_name]["jobs"] = [
            {
                "name": job_name,
                "descriptive_name": job_info.get("name"),
                "steps": [
                    step.get("name", step.get("uses"))
                    .replace(
                        "${{ github.event.repository.name }}", "<application-repo>"
                    )
                    .replace(
                        "${{ steps.branch_name.outputs.GH_REF_NAME }}",
                        "<feature-hotfix>",
                    )
                    for step in filter(steps_filter_criteria, job_info.get("steps", []))
                ],
            }
            for job_name, job_info in workflow["jobs"].items()
        ]
    return workflow_info


def make_markdown(workflow_info):
    toc = ""
    gh_actions_template = """
### {workflow_name}

Workflow file: `{workflow_file_name}`

Triggers:
- {workflow_triggers}

{workflow_inputs}

{workflow_outputs}

**Description:**

- {workflow_description}

{workflow_troubleshooting}

**Jobs:**

{workflow_jobs}
"""
    gh_actions = []
    for workflow_file_name, workflow in workflow_info.items():
        toc += f"- [{workflow['name']}](#{workflow["name"].lower().replace('/', '').replace(':', '').replace(' ', '-')})\n"

        workflow_name = workflow["name"]
        workflow_triggers = "\n- ".join(workflow["trigger"])
        workflow_inputs = ""
        if workflow["inputs"]:
            workflow_inputs = "Inputs:\n- " + "\n- ".join(workflow["inputs"])
        workflow_outputs = ""
        if workflow["outputs"]:
            workflow_outputs = "Outputs:\n- " + "\n- ".join(workflow["outputs"])
        workflow_description = "\n- ".join(workflow["description"])
        workflow_troubleshooting = ""
        if workflow["troubleshooting"]:
            workflow_troubleshooting = "**Troubleshooting:**\n- " + "\n- ".join(
                workflow["troubleshooting"]
            )
        workflow_jobs = ""
        for job in workflow["jobs"]:
            job_name = job["descriptive_name"] or job["name"]
            workflow_jobs += "- " + job_name + "\n"
            for step in job["steps"]:
                workflow_jobs += "\t- `" + step + "`\n"
            workflow_jobs += "\n"
        gh_actions.append(
            gh_actions_template.format(
                workflow_name=workflow_name,
                workflow_file_name=workflow_file_name,
                workflow_triggers=workflow_triggers,
                workflow_inputs=workflow_inputs,
                workflow_outputs=workflow_outputs,
                workflow_description=workflow_description,
                workflow_troubleshooting=workflow_troubleshooting,
                workflow_jobs=workflow_jobs,
            )
        )
    return toc, gh_actions


workflow_files = get_workflow_files()
workflow_info = get_workflow_info(workflow_files)
with open(os.path.join(DOCS_JSON_FILE), "w") as file:
    json.dump(workflow_info, file, indent=2)

toc, gh_actions = make_markdown(workflow_info)
with open(os.path.join(CICD_DEPLOYMENT_SCRIPTS_DIR, "README.md"), "w") as f:
    f.write(README_TEMPLATE.format(toc=toc, gh_actions="\n\n".join(gh_actions)))
