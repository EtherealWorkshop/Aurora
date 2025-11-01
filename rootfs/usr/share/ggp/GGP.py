from flask import Flask, request, render_template_string, send_from_directory, abort, session, redirect, url_for, after_this_request
import os
from os.path import dirname
import bcrypt
from werkzeug.utils import secure_filename
from datetime import datetime, timedelta
from pathlib import Path
import hashlib

app = Flask(__name__)
app.permanent_session_lifetime = timedelta(minutes=30)

skidproofing = [
    "/usr/share/aurora/aurora.sh",
    "/sbin/init",
    "/.crosenv",
]

def is_protected_path(path):
    abs_path = os.path.abspath(path)
    for protected in skidproofing:
        protected_abs = os.path.abspath(protected)
        if abs_path == protected_abs or abs_path.startswith(protected_abs + os.sep):
            return True
    return False


def binarycheck(filepath, blocksize=512):
    try:
        with open(filepath, 'rb') as f:
            block = f.read(blocksize)
            if b'\0' in block:
                return True
    except Exception:
        return True
    return False

def gethashpass():
    pw = os.environ.get("readpassword")
    if not pw:
        raise RuntimeError("password not set")
    pw_bytes = pw.encode()
    hashed_pw = bcrypt.hashpw(pw_bytes, bcrypt.gensalt())
    secret_key = hashlib.sha256(pw_bytes).digest()
    return hashed_pw, secret_key

passhash, secret_key = gethashpass()
app.secret_key = secret_key

def getlang(path):
    ext = Path(path).suffix.lower().lstrip(".")
    return {
        "sh": "shell",
        "py": "python",
        "js": "javascript",
        "ts": "typescript",
        "json": "json",
        "html": "html",
        "css": "css",
        "md": "markdown",
        "java": "java",
        "c": "c",
        "cpp": "cpp",
        "xml": "xml",
        "yml": "yaml",
        "yaml": "yaml",
        "go": "go",
        "rs": "rust",
        "php": "php",
        "sql": "sql",
        "ini": "ini",
    }.get(ext, "plaintext")

def validpass(pw):
    return bcrypt.checkpw(pw.encode(), passhash)

def passprompt():
    return f'''
    <!DOCTYPE html>
    <html>
    <head>
        <title>Aurora File Transfer - Grug Gateway Protocol</title>
        <link rel="stylesheet" href="/static/style.css">
        <link rel="preconnect" href="https://fonts.googleapis.com">
        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
        <link href="https://fonts.googleapis.com/css2?family=Roboto+Mono:ital,wght@0,100..700;1,100..700&display=swap" rel="stylesheet">
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    </head>
    <body>
        <h1>Aurora File Transfer - Grug Gateway Protocol</h1>
        <form method="post">
            <input class="file " type="password" name="password" placeholder="Password" required autofocus>
        </form>
    </body>
    </html>
    '''

@app.route("/", methods=["GET", "POST"])
def main():
    if request.method == "POST":
        pw = request.form.get("password", "")
        if validpass(pw):
            session['authenticated'] = True
            session.permanent = True
            return redirect(url_for("browse"))
        else:
            return passprompt("Invalid password, try again")
    return passprompt()
def check_auth():
    if not session.get('authenticated'):
        return False
    return True

@app.route("/logout")
def logout():
    session.clear()
    return passprompt("Logged out. Please login again.")

@app.route("/browse/", defaults={"path": ""}, methods=["GET", "POST"])
@app.route("/browse/<path:path>", methods=["GET", "POST"])
def browse(path, password=None):
    if not check_auth():
        return redirect('/')
    now = datetime.now().strftime("%H:%M %b %d")

    fullpath = os.path.join("/", path)
    if not os.path.exists(fullpath):
        abort(404)

    if os.path.isfile(fullpath):
        @after_this_request
        def cleanup(response):
            try:
                if fullpath.startswith("/tmp/") and os.path.exists(fullpath):
                    os.remove(fullpath)
            except Exception:
                pass
            return response
        return send_from_directory(os.path.dirname(fullpath), os.path.basename(fullpath))

    items = []
    parentpath = os.path.normpath(os.path.join(path, ".."))
    if parentpath == ".":
        parentpath = ""
    items.append({"name": "../", "path": parentpath, "is_dir": True})

    try:
        entries = os.listdir(fullpath)
    except PermissionError:
        entries = []

    def humanreadable(size_bytes):
        if size_bytes == 0:
            return "0 B"
        units = ["B", "KB", "MB", "GB", "TB"]
        i = 0
        while size_bytes >= 1024 and i < len(units) - 1:
            size_bytes /= 1024.0
            i += 1
        return f"{size_bytes:.2f} {units[i]}"

    for entry in sorted(entries):
        if entry in (".", ".."):
            continue
        entrypath = os.path.join(path, entry)
        entrypathfull = os.path.join(fullpath, entry)
        is_dir = os.path.isdir(entrypathfull)
        is_binary = False
        size = "-"
        mtime = "-"
        if not is_dir:
            try:
                size = humanreadable(os.path.getsize(entrypathfull))
                mtime = datetime.fromtimestamp(os.path.getmtime(entrypathfull)).strftime("%Y-%m-%d %H:%M")
            except Exception:
                pass
            is_binary = binarycheck(entrypathfull)
        items.append({
            "name": entry,
            "path": entrypath,
            "is_dir": is_dir,
            "is_binary": is_binary,
            "size": size,
            "mtime": mtime
    })

    return render_template_string('''
    <!DOCTYPE html>
    <html>
    <head>
    <head>
        <title>Aurora File Transfer - Grug Gateway Protocol</title>
        <link rel="stylesheet" href="/static/style.css">
        <link rel="preconnect" href="https://fonts.googleapis.com">
        <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
        <link href="https://fonts.googleapis.com/css2?family=Roboto+Mono:ital,wght@0,100..700;1,100..700&display=swap" rel="stylesheet">
        <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css">
    </head>
    <body>

        <h1>Aurora File Transfer - Grug Gateway Protocol</h1>
        <form class="upload" id="upload-form" action="/upload/{{path}}" method="post" enctype="multipart/form-data">
            <input type="file" id="file-input" hidden>
            <label for="file-input" id="file-label" class="file file-label" style="text-align: center;">Upload File</label>
        </form>
                                        
        <pre class="file">Aurora <span class="time">{{current_time}}</span>
        {% set parts = path.strip('/').split('/') if path else [] %}
        <a href="/browse/" class="path">/</a>
        {% set cum = [] %}
        {% for part in parts %}
        {% set _ = cum.append(part) %}
        <a href="/browse/{{ '/'.join(cum) }}" class="path">{{ part }}/</a>
        {% endfor %}
        </pre>


                                  
        <div class="file-list" role="list">
        {% for item in items %}
        <div class="file">
            <a class="filename" href="{% if item.is_dir %}/browse/{{item.path}}{% elif not item.is_binary %}/edit/{{item.path}}{% else %}/browse/{{item.path}}{% endif %}">
                {{ item.name }}{{ '/' if item.is_dir and not item.name.endswith('/') else '' }}
            </a>
            <a class="date" href="{% if item.is_dir %}/browse/{{item.path}}{% elif not item.is_binary %}/edit/{{item.path}}{% else %}/browse/{{item.path}}{% endif %}">
                {% if not item.is_dir %} {{ item.mtime }} {% endif %}
            </a>
            <a class="size" href="{% if item.is_dir %}/browse/{{item.path}}{% elif not item.is_binary %}/edit/{{item.path}}{% else %}/browse/{{item.path}}{% endif %}">
                {% if not item.is_dir %} {{ item.size }} {% endif %}
            </a>
        </div>
        {% endfor %}
        </div>
        <pre id="upload-status"></pre>

        <script>
        const form = document.getElementById('upload-form');
        const status = document.getElementById('upload-status');
        const fileInput = document.getElementById('file-input');
        const fileLabel = document.getElementById('file-label');

        function uploadFile() {
            status.textContent = '';
            if (!fileInput.files.length) {
                status.textContent = 'No file selected. (how)?';
                return;
            }

            const file = fileInput.files[0];
            fileLabel.textContent = `${file.name}`;

            const xhr = new XMLHttpRequest();
            xhr.open('POST', form.action);

            xhr.upload.onprogress = function(event) {
                if (event.lengthComputable) {
                    const percent = Math.floor((event.loaded / event.total) * 100);
                    const barLength = 20;
                    const filledLength = Math.floor(barLength * percent / 100);
                    const bar = '='.repeat(filledLength) + (filledLength < barLength ? '>' : '') + ' '.repeat(barLength - filledLength - (filledLength < barLength ? 1 : 0));
                    status.textContent = `Uploading: ${percent}% [${bar}]`;
                }
            };

            xhr.onload = function() {
                if (xhr.status === 200 || xhr.status === 204) {
                    status.textContent = `Upload complete`;
                    setTimeout(() => window.location.reload(), 500);
                } else {
                    status.textContent = `Upload failed`;
                }
            };

            xhr.onerror = function() {
                status.textContent = `Upload error`;
            };

            const formData = new FormData();
            formData.append('file', file);
            xhr.send(formData);
        }

        fileInput.addEventListener('change', function() {
            if (fileInput.files.length > 0) {
                uploadFile();
            }
        });
        </script>
    </body>
    </html>
    ''', path=path, password=password, items=items, current_time=now)

@app.route("/edit/<path:path>", methods=["GET", "POST"])
def edit(path):
    if not check_auth():
        return redirect('/')

    fullpath = os.path.join("/", path)

    if is_protected_path(fullpath):
        abort(403, "what are you trying to do, break the shim?")

    if not os.path.exists(fullpath) or not os.path.isfile(fullpath):
        abort(404)

    if request.method == "POST":
        action = request.form.get("action", "save")
        content = request.form.get("content", "").replace('\r\n', '\n')
        try:
            with open(fullpath, "w", encoding="utf-8") as f:
                f.write(content)
            if action == "save_exit":
                return f'<script>window.location.href="/browse/{dirname(path)}";</script>'
            return "", 204
        except Exception as e:
            return f'Error saving file: {e}', 500

    try:
        with open(fullpath, "r", encoding="utf-8") as f:
            filecontent = f.read()
    except Exception as e:
        filecontent = f"Error reading file: {e}"

    language = getlang(path)
    pathdir = dirname(path)

    return render_template_string('''
    <!DOCTYPE html>
    <html>
    <head>
        <title>Editing {{ path }}</title>
        <script src="https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.44.0/min/vs/loader.min.js"></script>
        <script>
        require.config({ paths: { 'vs': 'https://cdnjs.cloudflare.com/ajax/libs/monaco-editor/0.44.0/min/vs' }});
        </script>
        <link rel="stylesheet" href="/static/style.css">
    </head>
    <body>
        <div class="topbar">
            <button onclick="submitForm('save')">Save</button>
            <button onclick="submitForm('save_exit')">Save & Exit</button>
            <button onclick="exitWithoutSaving()">Exit Without Saving</button>
            <span style="margin-left:auto;">
            {%- set parts = path.strip('/').split('/') -%}
            {%- set cumulative_path = '' -%}
            <a href="/browse/">/</a>
            {%- for part in parts[:-1] %}
                {%- set cumulative_path = cumulative_path + '/' + part -%}
                <a href="/browse{{ cumulative_path }}">{{ part }}</a> /
            {%- endfor %}
            {{ parts[-1] }}
            </span>
        </div>

        <form id="editor-form" method="post" style="display:none;">
            <input type="hidden" name="content" id="content-input">
            <input type="hidden" name="action" id="form-action" value="save">
        </form>

        <div id="editor"></div>

        <script>
        let editor;

        require(["vs/editor/editor.main"], function () {
            editor = monaco.editor.create(document.getElementById("editor"), {
                value: {{ filecontent | tojson }},
                language: "{{ language }}",
                theme: "vs-dark",
                automaticLayout: true
            });

            window.addEventListener("keydown", function(e) {
                if ((e.ctrlKey || e.metaKey) && e.key === 's') {
                    e.preventDefault();
                    submitForm('save');
                }
            });
        });

        function submitForm(action) {
            const input = document.getElementById("content-input");
            const form = document.getElementById("editor-form");
            const formAction = document.getElementById("form-action");
            input.value = editor.getValue();
            formAction.value = action;
            form.submit();
        }

        function exitWithoutSaving() {
            window.location.href = "/browse/{{ pathdir }}";
        }
        </script>
    </body>
    </html>
    ''', path=path, filecontent=filecontent, language=language, pathdir=pathdir)

@app.route("/upload/", defaults={"path": ""}, methods=["POST"])
@app.route("/upload/<path:path>", methods=["POST"])
def upload(path):
    if not check_auth():
        return redirect('/')
    basedir = os.path.join("/", path)
    tdir = os.path.realpath(basedir)

    if is_protected_path(tdir):
        abort(403, "what are you trying to do, break the shim?")

    file = request.files.get("file")
    if file:
        filename = secure_filename(file.filename)
        savedir = os.path.join(tdir, filename)
        savedir = os.path.realpath(savedir)

        if is_protected_path(savedir):
            abort(403, "what are you trying to do, break the shim?")

        try:
            os.makedirs(tdir, exist_ok=True)
            file.save(savedir)
        except Exception as e:
            if os.path.exists(savedir):
                try:
                    os.remove(savedir)
                except Exception as rm_e:
                    print(f"Failed to delete {rm_e}")
            return f"Upload failed.", 500

    return '', 204


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=42069)
