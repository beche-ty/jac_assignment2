
import from byllm.lib { Model }
import os;
import uuid;


import from  datetime { datetime }

import os;



# ADD YOU api_key to the "GEMINI_API_KEY" environment variable before running.

glob llm = Model(model_name="gemini/gemini-2.5-flash",api_key="", temperature=0.2, max_tokens=4000);

# ==== OBJECTS ====
obj RepoInfo {
    has repo_url: str = "";
    has save_path: str = "";
    has documentation: str = "";
    has status: str = "pending";
}

obj RepoResult {
    has repo_url: str = "";
    has status: str = "";
    has doc_preview: str = "";
    has full_doc: str = "";
    has save_path: str = "";
    has structure: str = "";
    has readme_summary: str = "";
    has analysis_summary: str = "";
    has partial_analyses: list[str] = [];
    has generated_at: str = "";
}

# ==== AI TASK DECLARATIONS ====
def analyze_repo_structure(repo_url: str, code_snippets:str) -> str by llm(method="Reason");
def generate_repo_docs(repo_url: str, summary: str) -> str by llm(method="Reason");

# ==== NODE DEFINITIONS ====
node RepoNode {
    has repo: RepoInfo =RepoInfo();
    has result: RepoResult =RepoResult();

    def setup_repo(url: str) {
        self.repo = RepoInfo();
        self.repo.repo_url = url;
        self.repo.save_path = "./outputs/codegenius_repo_" + str(uuid.uuid4());
    }

    def clone_repo() {
        print("📦 Cloning repository: " + self.repo.repo_url);

        parent = os.path.dirname(self.repo.save_path);
        if parent != "" and not os.path.exists(parent) {
            os.makedirs(parent, exist_ok=True);
            }


        cmd = "git clone " + self.repo.repo_url + " " + self.repo.save_path;
        out = os.system(cmd);
        if out == 0 {
            print("✅ Repository cloned successfully!");
            self.repo.status = "success";
        } else {
            print("❌ Failed to clone repository (git exit code: " + str(out) + ").");
            self.repo.status = "failed";
        }
    }

    def scan_files(path: str) -> list[str] {
        items = [];
        if not os.path.exists(path) { return items; }


        for f in os.listdir(path) {
            if f in [".git", "node_modules"] { continue; }

            full_path = path + "/" + f;
            if os.path.isdir(full_path) {
                items = items + self.scan_files(full_path);
            } elif os.path.isfile(full_path) {
                if f.endswith(".py") || f.endswith(".js") || f.endswith(".jac") ||
                   f.endswith(".ipynb") || f.endswith(".md") || f.endswith(".txt") ||
                   f.endswith(".yml") {
                    items = items + [full_path];  # store full path
                }
            }
        }
        return items;
    }

    def read_files(files: list[str]) -> map[str,str] {
    contents = {};
    for f in files {
         handle = open(f, "r", encoding="utf-8", errors="ignore");
        if handle != None {
            data = handle.read();
            handle.close();

            # truncate safely
            if len(data) > 3000 { data = data[0:3000]; }

            contents[f] = data;
        } else {
            print("⚠️ Could not open file: " + f);
            contents[f] = "";
        }
    }
    return contents;
}


    def build_ccg(file_contents: map[str,str]) -> str {
        ccg = "";
        for f in file_contents {
            content = file_contents[f];
            lines = content.split("\n");
            for line in lines {
                line = line.strip();
                if line.startswith('def ') || line.startswith("class ") {
                    ccg = ccg + f + ": " + line + "\n";
                }
            }
        }
        if ccg == "" { ccg = "No functions or classes detected."; }
        return ccg;
    }

   def analyze_and_document() {
    print("🧠 Starting analysis...");

    # 1️⃣ Scan repo files
    files = self.scan_files(self.repo.save_path);
    print("📂 Files found: " + str(len(files)));

    # 2️⃣ Read file contents
    file_contents = self.read_files(files);

    # 3️⃣ Detect README and requirements
    readme = "";
    requirements = "";
    for f in file_contents {
        fname = str(os.path.basename(f)).lower();
        if fname == "readme.md" { readme = file_contents[f]; }
        if fname == "requirements.txt" || fname == "environment.yml" { requirements = file_contents[f]; }
    }

    # 4️⃣ Build partial code context (first few files)
    temp_list = [];
    count = 0;
    for f in file_contents {
        if count >= 5 { break; }
        # Ask AI to analyze individual file
        analysis = analyze_repo_structure(f, file_contents[f]);
        temp_list = temp_list + [analysis];
        count = count + 1;
    }
    self.result.partial_analyses = temp_list;

    # 5️⃣ Build overall code context graph (simple headers/functions)
    ccg = self.build_ccg(file_contents);

    # 6️⃣ Prepare full summary for AI documentation
    full_summary = "Repository URL: " + self.repo.repo_url + "\n\n";
    full_summary = full_summary + "Files scanned:\n" + "\n".join(files) + "\n\n";
    full_summary = full_summary + "Code Context Graph:\n" + ccg + "\n\n";

    if requirements != "" { full_summary = full_summary + "Installation / Requirements:\n```\n" + requirements + "\n```\n\n"; }
    if readme != "" { full_summary = full_summary + "README Summary:\n" + slice(readme,0,1000) + "\n\n"; }

    # 7️⃣ Ask AI to generate repository documentation
    doc = generate_repo_docs(self.repo.repo_url, full_summary);
    if doc == "" { doc = full_summary; }

    # 8️⃣ Populate result object
    self.repo.documentation = doc;
    self.result.repo_url = self.repo.repo_url;
    self.result.status = self.repo.status;
    self.result.doc_preview = doc[0:800];
    self.result.full_doc = doc;
    self.result.generated_at = str(datetime.now());
    self.result.structure = "\n".join(files);

    if readme != "" {
        self.result.readme_summary = readme[0:1000] + "...";
    } else {
        self.result.readme_summary = "No README found.";
    }

    # 9️⃣ Ask AI for overall repo analysis summary
    code_for_summary = "";
    for f in file_contents {
        code_for_summary = code_for_summary + "File: " + f + "\n" + file_contents[f] + "\n\n";
    }
    self.result.analysis_summary = analyze_repo_structure(self.repo.repo_url, code_for_summary);

    print("✅ Documentation ready!");
    }
}



# ==== WALKER ====
walker RepoDocAgent {
    has repo_url: str;
    has result: RepoResult = {};

    can start with `root entry {
        print("🚀 Starting RepoDocAgent");
        print("Repository URL: " + self.repo_url);

        repo_node = RepoNode();
        repo_node.setup_repo(self.repo_url);

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
