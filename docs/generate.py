#!/usr/bin/env python3

# Minimal doc generator for layers

import os
import sys
from pathlib import Path
import tempfile
from jinja2 import Environment, FileSystemLoader

script_dir = Path(__file__).parent
sys.path.insert(0, str(script_dir.parent / 'site'))
from layer_manager import LayerManager
from validators import get_validator_documentation_data


def md2html(content: str, format: str = 'asciidoc') -> str:
    import subprocess

    supported_formats = {'asciidoc', 'markdown'}
    if format not in supported_formats:
        supported = ', '.join(supported_formats)
        raise ValueError(f"Unsupported format '{format}'. Supported: {supported}")

    html_output = None
    
    # Try the best tool for each format
    if format == 'asciidoc':
        try:
            result = subprocess.run([
                'asciidoctor', 
                '-b', 'html5',  # HTML5 backend
                '-s',           # Suppress header/footer
                '-a', 'table-frame=all',    # Table frame
                '-a', 'table-grid=all',     # Table grid
                '-a', 'table-stripes=even', # Table striping
                '-'
            ], input=content, capture_output=True, text=True, check=True)
            html_output = result.stdout
        except (subprocess.CalledProcessError, FileNotFoundError):
            print("asciidoctor not found - falling back")
            pass

    elif format == 'markdown':
        try:
            import markdown
            md = markdown.Markdown(extensions=['tables', 'fenced_code', 'toc'])
            html_output = md.convert(content)
        except ImportError:
            print("markdown not found - falling back")
            pass

    # fallback to pandoc
    if html_output is None:
        print('fallback to pandoc for conversion from ', format)
        try:
            result = subprocess.run(
                ['pandoc', '-f', format, '-t', 'html', '-'],
                input=content,
                capture_output=True,
                text=True,
                check=True
            )
            html_output = result.stdout
        except (subprocess.CalledProcessError, FileNotFoundError):
            raise Exception("Fallback conversion failed for format", format)

    # Post-process: convert .adoc links to .html for web navigation
    import re
    html_output = re.sub(r'href="([^"]+)\.adoc"', r'href="\1.html"', html_output)
    return html_output


def main():
    script_dir = Path(__file__).parent  # The docs/ directory
    doc_dir = script_dir  # Generate in the docs directory
    layer_dir = doc_dir / 'layer'
    config_dir = doc_dir / 'config'
    prov_dir = doc_dir / 'provisioning'
    exec_dir = doc_dir / 'execution'
    templates_dir = script_dir.parent / 'templates' / 'docs' / 'html'

    # jinja init
    env = Environment(loader=FileSystemLoader(str(templates_dir)))

    # Load layers
    layer_paths = [
        str(script_dir.parent / 'device'),
        str(script_dir.parent / 'image'),
        str(script_dir.parent / 'layer')
    ]

    bin_dir = script_dir.parent / 'bin'
    gen_dir = bin_dir / 'generators'
    os.environ["PATH"] = f"{gen_dir}:{bin_dir}:{os.environ['PATH']}"

    with tempfile.TemporaryDirectory(prefix="layer-docs-") as tmp_root:
        tmpdir = Path(tmp_root)
        layer_paths = [f"DYNlayer={tmpdir}"] + layer_paths
        manager = LayerManager(layer_paths, doc_mode=True, fail_on_lint=True)

        # Docs cannot be generated if there are load/lint errors
        if manager.load_errors:
            msgs = "\n".join(f"{k}: {v}" for k, v in manager.load_errors.items())
            raise SystemExit(f"Aborting docs generation due to layer load errors:\n{msgs}")

        # All layer names
        layer_names = sorted(manager.layers.keys())

        # Do it
        layer_template = env.get_template('layer.html')
        layers_info = []

        for layer_name in layer_names:
            doc_data = manager.get_layer_documentation_data(layer_name)
            if doc_data:
                # If present, convert companion doc to HTML
                if doc_data.get('companion_doc'):
                    print('Companion: ', layer_name)
                    doc_data['companion_html'] = md2html(doc_data['companion_doc'])
                else:
                    doc_data['companion_html'] = ""

                # Render layer page
                html_content = layer_template.render(layer=doc_data)

                # Write layer page
                layer_file = layer_dir / f"{layer_name}.html"
                layer_file.write_text(html_content)

                # Collect info for index
                layers_info.append({
                    'name': layer_name,
                    'description': doc_data['layer_info'].get('description', 'No description'),
                    'category': doc_data['layer_info'].get('category', 'uncategorised'),
                    'filename': f"layer/{layer_name}.html"
                })

                print(f"Generated: {layer_file}")

        # Generate main index page
        index_md = script_dir / 'index.adoc'
        if index_md.exists():
            md_content = index_md.read_text()
            index_content = md2html(md_content)
        else:
            raise Exception("No content for top level index!")

        # Render main index page
        index_template = env.get_template('index.html')
        index_html = index_template.render(
            content=index_content,
            layers=[]  # No layers on main page
        )

        # Write main index page
        index_file = doc_dir / 'index.html'
        index_file.write_text(index_html)
        print(f"Generated: {index_file}")


        # Generate config index page
        index_md = config_dir / 'index.adoc'
        if index_md.exists():
            md_content = index_md.read_text()
            index_content = md2html(md_content)
        else:
            raise Exception("No content for config index!")

        # Render config index page
        index_template = env.get_template('index.html')
        index_html = index_template.render(
            content=index_content,
            layers=[]  # No layers
        )

        # Write config index page
        index_file = config_dir / 'index.html'
        index_file.write_text(index_html)
        print(f"Generated: {index_file}")



        # Generate provisioning index page
        index_md = prov_dir / 'index.adoc'
        if index_md.exists():
            md_content = index_md.read_text()
            index_content = md2html(md_content)
        else:
            raise Exception("No content for provisioning index!")

        # Render config index page
        index_template = env.get_template('index.html')
        index_html = index_template.render(
            content=index_content,
            layers=[]  # No layers
        )

        # Write provisioning index page
        index_file = prov_dir / 'index.html'
        index_file.write_text(index_html)
        print(f"Generated: {index_file}")



        # Generate execution index page
        index_md = exec_dir / 'index.adoc'
        if index_md.exists():
            md_content = index_md.read_text()
            index_content = md2html(md_content)
        else:
            raise Exception("No content for execution index!")

        # Render execution index page
        index_template = env.get_template('index.html')
        index_html = index_template.render(
            content=index_content,
            layers=[]  # No layers
        )

        # Write execution index page
        index_file = exec_dir / 'index.html'
        index_file.write_text(index_html)
        print(f"Generated: {index_file}")



        # Generate layer index page
        layer_index_md = script_dir / 'layer' / 'index.adoc'
        if layer_index_md.exists():
            layer_md_content = layer_index_md.read_text()
            layer_index_content = md2html(layer_md_content)
        else:
            raise Exception("No content for layer index!")

        layer_index_template = env.get_template('layer-index.html')
        layer_index_html = layer_index_template.render(
            content=layer_index_content,
            layers=layers_info
        )

        # Write layer index page
        layer_index_file = layer_dir / 'index.html'
        layer_index_file.write_text(layer_index_html)
        print(f"Generated: {layer_index_file}")

        # Generate validation help page
        help_template = env.get_template('variable-validation.html')
        validation_data = get_validator_documentation_data()

        vars_html = help_template.render(validation=validation_data)
        vars_file = layer_dir / 'variable-validation.html'
        vars_file.write_text(vars_html)
        print(f"Generated: {vars_file}")

    print(f"\nDocumentation generated in {doc_dir}/")

if __name__ == '__main__':
    main()
