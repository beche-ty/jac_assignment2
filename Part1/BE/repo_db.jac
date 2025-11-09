import from byllm.lib { Model }
import os;
import datetime;
import uuid;

# ==== GLOBAL MODEL ====
glob llm = Model(model_name="gemini/gemini-2.5-flash", api_key="GEMINI_API_KEY");

# ==== OBJECTS ====
obj RepoInfo {
    has repo_url: str = "";
    has save_path: str = "./outputs/codegenius_repo_" + str(uuid.uuid4());
    has documentation: str = "";
    has status: str = "pending";
}

obj RepoResult {
    has repo_url: str = "";
    has status: str = "";
    has doc_preview: str = "";
    has save_path: str = "";
    has structure: str = "";
    has readme_summary: str = "";
    has analysis_summary: str = "";
    has partial_analyses: list[str] = [];
}

# ==== AI TASKS ====
def analyze_repo_structure(repo_url: str, file_list: list[str]) -> str by llm(method="Reason");
def generate_repo_docs(repo_url: str, summary: str) -> str by llm(method="Reason");

# ==== NODE DEFINITIONS ====
node RepoNode {
    has repo: RepoInfo = RepoInfo();
    has result: RepoResult = RepoResult();

    # --- Clone repository ---
    def clone_repo() {
        print("📦 Cloning repository: " + self.repo.repo_url);
        cmd = f"git clone {self.repo.repo_url} {self.repo.save_path}";
        out = os.system(cmd);
        if out == 0 {
            print("✅ Repository cloned successfully!");
            self.repo.status = "success";
        } else {
            print("❌ Failed to clone repository.");
            self.repo.status = "failed";
        }
    }

    # --- Recursive file scan ---
    def scan_files(path: str) -> list[str] {
        items = [];
        for f in os.listdir(path) {
            if f in [".git", "node_modules"] { continue; }
            full_path = path + "/" + f;
            if os.path.isdir(full_path) {
                items.append(f + "/");
                items += self.scan_files(full_path);
            } elif os.path.isfile(full_path) and f.endswith((".py", ".js", ".jac", ".ipynb", ".md", ".txt", ".yml")) {
                items.append(f);
            }
        }
        return items;
    }

    # --- Read files content ---
  def read_files(files: list[str], base_path: str) -> map[str, str] {
    contents = {};
    for f in files {
        path = base_path + "/" + f;
        if os.path.isfile(path) {
            with open(path, "r") as file{
                data = file.read();
                contents[f] = data[:3000]; } # safely truncate to 3000 chars
        }
    }
    return contents;
}


    # --- Build Code Context Graph (CCG) ---
    def build_ccg(file_contents: map[str, str]) -> str {
        ccg = "";
        for f in file_contents {
            content = file_contents[f];
            lines = content.split("\n");
            for line in lines {
                line = line.strip();
                if line.startswith("def ") or line.startswith("class ") {
                    ccg += f + ": " + line + "\n";
                }
            }
        }
        return ccg;
    }

    # --- Analyze repository and generate documentation ---
    def analyze_and_document() {
        print("🧠 Starting analysis...");

        files = self.scan_files(self.repo.save_path);
        file_contents = self.read_files(files, self.repo.save_path);

        readme = "";
        requirements = "";

        for f in file_contents {
            fname = f.lower();
            if fname == "readme.md" { readme = file_contents[f]; }
            if fname == "requirements.txt" or fname == "environment.yml" { requirements = file_contents[f]; }
        }

        print("🤖 Summarizing repo structure...");
        summary = analyze_repo_structure(self.repo.repo_url, files);

        print("🧩 Building Code Context Graph...");
        ccg = self.build_ccg(file_contents);

        print("📝 Generating final documentation...");
        full_summary = summary + "\n\nCode Context Graph:\n" + ccg;
        if requirements != "" { full_summary += "\n\nInstallation / Requirements:\n```\n" + requirements + "\n```"; }
        if readme != "" { full_summary += "\n\nREADME Summary:\n" + readme[:1000]; }

        self.repo.documentation = generate_repo_docs(self.repo.repo_url, full_summary);

        # --- Store results for frontend ---
        self.result.repo_url = self.repo.repo_url;
        self.result.status = self.repo.status;
        self.result.doc_preview = self.repo.documentation[:800];
        self.result.full_doc = self.repo.documentation;
        self.result.generated_at = datetime.datetime.now();
        self.result.structure = "\n".join(files);

        if readme != "" { self.result.readme_summary = readme[:1000] + "..."; } 
        else { self.result.readme_summary = "No README found."; }

        if ccg != "" { self.result.analysis_summary = ccg[:1000] + "..."; } 
        else { self.result.analysis_summary = "No analysis available."; }

        self.result.partial_analyses = [file_contents[f] for f in file_contents][:5];

        print("✅ Documentation ready!");
    }
}





# ==== WALKER ====
walker RepoDocAgent {
    has repo_url: str;
    has result: RepoResult = RepoResult();

    can start with `root entry {
        print("🚀 Starting RepoDocAgent");
        print("Repository URL: " + self.repo_url);

        repo_node = RepoNode();
        repo_node.repo.repo_url = self.repo_url;

        visit repo_node;
    }

    can visit with RepoNode entry {
        here.clone_repo();
        if here.repo.status == "success" {
            here.analyze_and_document();
            self.result = here.result;
            report {
                "status": "success",
                "repo_url": self.result.repo_url,
                "doc_preview": self.result.doc_preview,
                "save_path": self.result.save_path,
                "structure": self.result.structure,
                "readme_summary": self.result.readme_summary,
                "analysis_summary": self.result.analysis_summary,
                "partial_analyses": self.result.partial_analyses
            };
        } else {
            report { "status": "failed", "message": "Repository clone failed." };
        }
    }
}
