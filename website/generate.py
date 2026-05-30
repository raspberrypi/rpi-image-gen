#!/usr/bin/env python3

"""Generate Docusaurus input docs for rpi-image-gen.

The upstream generator continues to produce the standalone HTML docs under
``docs/``. This file only prepares temporary AsciiDoc/Markdown input for the
Docusaurus website under ``website/generated-docs/``.
"""

import argparse
import os
import re
import shutil
import sys
import tempfile
from pathlib import Path

from jinja2 import Environment, FileSystemLoader

script_dir = Path(__file__).parent
repo_root = script_dir.parent
docs_dir = repo_root / 'docs'

sys.path.insert(0, str(repo_root / 'site'))
from layer_manager import LayerManager  # noqa: E402
from validators import get_validator_documentation_data  # noqa: E402


def _stringify(value) -> str:
    if value is None:
        return ''
    if isinstance(value, (list, tuple, set)):
        return ', '.join(_stringify(item) for item in value)
    return str(value)


def adoc_cell(value) -> str:
    """Escape text for normal AsciiDoc table cells."""
    text = _stringify(value).strip()
    if not text:
        return '—'
    return (
        text
        .replace('\\', '\\\\')
        .replace('|', '\\|')
        .replace('\r\n', '\n')
        .replace('\r', '\n')
        .replace('\n', ' +\n')
    )


def adoc_literal(value) -> str:
    """Render a value as inline monospace while tolerating special characters."""
    text = _stringify(value)
    if text == '':
        text = '<empty>'
    return 'pass:q[`' + text.replace(']', '\\]') + '`]'


def default_value(var) -> str:
    if isinstance(var, dict):
        original = var.get('original_value')
        set_policy = var.get('set_policy')
        validation = var.get('validation_description')
    else:
        original = getattr(var, 'original_value', '')
        set_policy = getattr(var, 'set_policy', '')
        validation = getattr(var, 'validation_description', '')

    if original:
        return original
    if set_policy == 'skip':
        return '<disabled>'
    if validation and 'empty' in validation.lower():
        return '<empty>'
    return '<not set>'


def strip_document_title(content: str) -> str:
    """Avoid nesting a companion document title inside a generated layer page."""
    if not content:
        return ''
    lines = content.splitlines()
    if lines and lines[0].startswith('= '):
        return '\n'.join(lines[1:]).lstrip()
    return content


def docusaurus_slug(title: str) -> str:
    """Approximate heading ids produced by Docusaurus for simple headings."""
    title = re.sub(r'`([^`]+)`', r'\1', title)
    title = re.sub(r'\{#[^}]+\}\s*$', '', title).strip()
    return re.sub(r'[^A-Za-z0-9]+', '-', title.lower()).strip('-')


def normalise_asciidoc_anchors(content: str) -> str:
    """Normalize upstream AsciiDoc section xrefs for Docusaurus link checking.

    The Docusaurus AsciiDoc pipeline renders legacy AsciiDoc xrefs like
    ``<<slot-shared>>`` as ``#slot-shared`` links, but the generated heading id
    is based on the heading text, for example ``#slot-shared-application-data``.
    Rewrite those local xrefs to the Docusaurus heading slug while generating
    temporary docs.
    """
    anchor_to_slug: dict[str, str] = {}
    anchor_to_title: dict[str, str] = {}

    def section_anchor_replace(match: re.Match) -> str:
        anchor = match.group(1)
        level = match.group(2)
        title = match.group(3).strip()
        anchor_to_slug[anchor] = docusaurus_slug(title)
        anchor_to_title[anchor] = re.sub(r'`([^`]+)`', r'\1', title)
        return f'{level} {title}'

    content = re.sub(
        r'(?m)^\[\[([A-Za-z0-9_.:-]+)\]\]\s*\n^(=+)\s+(.+)$',
        section_anchor_replace,
        content,
    )

    def xref_replace(match: re.Match) -> str:
        anchor = match.group(1)
        label = match.group(2) or anchor_to_title.get(anchor) or anchor
        slug = anchor_to_slug.get(anchor)
        if not slug:
            return match.group(0)
        return f'link:#{slug}[{label}]'

    content = re.sub(r'<<([A-Za-z0-9_.:-]+)(?:,([^>]+))?>>', xref_replace, content)

    # For non-section anchors, keep an explicit block anchor as a fallback.
    return re.sub(r'(?m)^\[\[([A-Za-z0-9_.:-]+)\]\]$', r'[#\1]', content)


def split_target(target: str) -> tuple[str, str]:
    match = re.match(r'^([^#]*)(#.*)?$', target)
    if not match:
        return target, ''
    return match.group(1), match.group(2) or ''


def is_external_target(target: str) -> bool:
    return (
        target.startswith(('http://', 'https://', 'mailto:', 'tel:', 'data:')) or
        target.startswith('#') or
        target.startswith('{')
    )


def docusaurus_route_target(target: str) -> str:
    """Convert static-site .adoc/.html targets into extensionless Docusaurus routes."""
    path_part, anchor = split_target(target)

    if path_part.endswith('/index.adoc') or path_part.endswith('/index.html'):
        path_part = path_part.rsplit('/', 1)[0] + '/'
    elif path_part in ('index.adoc', './index.adoc', 'index.html', './index.html'):
        path_part = './'
    elif path_part.endswith('.adoc'):
        path_part = path_part[:-len('.adoc')] + '/'
    elif path_part.endswith('.html'):
        path_part = path_part[:-len('.html')] + '/'

    path_part = re.sub(r'/+', '/', path_part)
    return path_part + anchor


def rewrite_static_site_links(content: str) -> str:
    """Rewrite AsciiDoc links copied from docs/ for Docusaurus routing."""

    def replace(match: re.Match) -> str:
        target = match.group(1)
        label = match.group(2)
        if is_external_target(target):
            return match.group(0)
        return f'link:{docusaurus_route_target(target)}[{label}]'

    content = re.sub(r'link:([^\[]+)\[([^\]]*)\]', replace, content)
    return normalise_asciidoc_anchors(content)


def build_layer_name_maps(manager: LayerManager) -> tuple[dict[Path, str], dict[str, list[str]]]:
    by_companion_path: dict[Path, str] = {}
    by_stem: dict[str, list[str]] = {}

    for layer_name, layer_file in manager.layer_files.items():
        yaml_path = Path(layer_file).resolve()
        for suffix in ('.adoc', '.md', '.html'):
            by_companion_path[yaml_path.with_suffix(suffix)] = layer_name
        by_stem.setdefault(yaml_path.stem, []).append(layer_name)
        by_stem.setdefault(layer_name, []).append(layer_name)

    return by_companion_path, by_stem


def layer_name_for_target(
    target_path: Path,
    by_companion_path: dict[Path, str],
    by_stem: dict[str, list[str]],
) -> str | None:
    resolved = target_path.resolve()
    if resolved in by_companion_path:
        return by_companion_path[resolved]

    candidates = by_stem.get(target_path.stem, [])
    if len(set(candidates)) == 1:
        return candidates[0]

    suffix_matches = [
        name for name in candidates
        if name.endswith('-' + target_path.stem)
    ]
    if len(set(suffix_matches)) == 1:
        return suffix_matches[0]

    return None


def rewrite_companion_links(
    content: str,
    companion_path: Path,
    by_companion_path: dict[Path, str],
    by_stem: dict[str, list[str]],
) -> str:
    """Rewrite links embedded from source companion docs into generated layer pages.

    Companion docs live beside YAML files in layer/device/image directories, but in
    Docusaurus they are embedded in generated pages under docs/layer/<layer>/.
    Relative links therefore need to be translated to the generated docs tree.
    """
    source_dir = companion_path.parent

    def replace(match: re.Match) -> str:
        target = match.group(1)
        label = match.group(2)
        if is_external_target(target):
            return match.group(0)

        path_part, anchor = split_target(target)
        target_path = (source_dir / path_part).resolve()

        layer_name = layer_name_for_target(target_path, by_companion_path, by_stem)
        if layer_name:
            return f'link:../{layer_name}/{anchor}[{label}]'

        # Known original static-site documentation targets referenced by companion docs.
        if path_part.endswith('provisioning/index.html') or path_part.endswith('provisioning/index.adoc'):
            return f'link:../../provisioning/{anchor}[{label}]'

        if '/schemas/' in path_part or path_part.startswith('../schemas/'):
            return f'link:../../{docusaurus_route_target(path_part).lstrip("./")}{anchor}[{label}]'

        return f'link:{docusaurus_route_target(target)}[{label}]'

    content = re.sub(r'link:([^\[]+)\[([^\]]*)\]', replace, content)
    return normalise_asciidoc_anchors(content)


def fix_schema_markdown(content: str) -> str:
    """Make generated schema Markdown compatible with Docusaurus link checking."""
    # json-schema-for-humans emits links such as (#anchor ) with a trailing space.
    content = re.sub(r'\(#([^\)\s]+)\s+\)', r'(#\1)', content)

    # json-schema-for-humans can also emit empty-label links such as
    # [](#some_anchor) for anonymous additionalProperties rows. There is no
    # corresponding heading for those anchors, so Docusaurus correctly reports
    # them as broken. Keep the table cell content but remove the dead link.
    content = re.sub(r'\[\]\(#[^\)]+\)', '-', content)

    # Convert headings like "## <a name=\"id\"></a>Title" to Docusaurus custom IDs.
    def heading_replace(match: re.Match) -> str:
        level = match.group(1)
        anchor = match.group(2)
        title = match.group(3).strip()
        return f'{level} {title} {{#{anchor}}}'

    content = re.sub(
        r'^(#{1,6})\s+<a\s+name="([^"]+)"></a>\s*(.*?)$',
        heading_replace,
        content,
        flags=re.MULTILINE,
    )

    return content


def write_text(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content.rstrip() + '\n', encoding='utf-8')
    print(f'Generated: {path}')


def create_adoc_environment(templates_dir: Path) -> Environment:
    env = Environment(
        loader=FileSystemLoader(str(templates_dir)),
        trim_blocks=True,
        lstrip_blocks=True,
    )
    env.filters['cell'] = adoc_cell
    env.filters['literal'] = adoc_literal
    env.filters['default_value'] = default_value
    env.filters['strip_document_title'] = strip_document_title
    return env


def load_layer_manager() -> LayerManager:
    layer_paths = [
        str(repo_root / 'device'),
        str(repo_root / 'image'),
        str(repo_root / 'layer'),
    ]

    bin_dir = repo_root / 'bin'
    gen_dir = bin_dir / 'generators'
    os.environ['PATH'] = f"{gen_dir}:{bin_dir}:{os.environ['PATH']}"

    tmp_root = tempfile.TemporaryDirectory(prefix='layer-docs-')
    tmpdir = Path(tmp_root.name)
    layer_paths = [f'DYNlayer={tmpdir}'] + layer_paths
    manager = LayerManager(layer_paths, doc_mode=True, fail_on_lint=True)
    manager._docs_tmp_root = tmp_root  # Keep temporary directory alive with the manager.

    if manager.load_errors:
        msgs = '\n'.join(f'{k}: {v}' for k, v in manager.load_errors.items())
        raise SystemExit(f'Aborting docs generation due to layer load errors:\n{msgs}')

    return manager


def copy_manual_doc(source: Path, output_dir: Path) -> None:
    rel = source.relative_to(docs_dir)
    content = rewrite_static_site_links(source.read_text(encoding='utf-8'))
    write_text(output_dir / rel, content)


def copy_schema_doc(source: Path, output_dir: Path) -> None:
    # Original static docs expose these through docs/schemas -> ../layer/rpi/schemas.
    # In Docusaurus mode they become normal docs under /docs/schemas/...
    rel = source.relative_to(repo_root / 'layer' / 'rpi' / 'schemas')
    content = fix_schema_markdown(source.read_text(encoding='utf-8'))
    write_text(output_dir / 'schemas' / rel, content)


def generate_docusaurus_docs(output_dir: Path) -> None:
    """Generate Docusaurus input files without touching upstream HTML output."""
    if output_dir.exists():
        shutil.rmtree(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    layer_dir = output_dir / 'layer'
    templates_dir = script_dir / 'templates' / 'asciidoc'

    env = create_adoc_environment(templates_dir)
    manager = load_layer_manager()
    by_companion_path, by_stem = build_layer_name_maps(manager)
    layer_names = sorted(manager.layers.keys())

    # Copy the hand-written docs that make up the original static site.
    for source in (
        docs_dir / 'index.adoc',
        docs_dir / 'config' / 'index.adoc',
        docs_dir / 'execution' / 'index.adoc',
        docs_dir / 'provisioning' / 'index.adoc',
    ):
        copy_manual_doc(source, output_dir)

    # Copy generated schema Markdown into the same route shape the original docs used.
    for schema_doc in sorted((repo_root / 'layer' / 'rpi' / 'schemas').glob('**/schema.md')):
        copy_schema_doc(schema_doc, output_dir)

    layer_template = env.get_template('layer.adoc.j2')
    layers_info = []

    for layer_name in layer_names:
        doc_data = manager.get_layer_documentation_data(layer_name)
        if not doc_data:
            continue

        companion_path = Path(manager.layer_files[layer_name]).with_suffix('.adoc')
        if doc_data.get('companion_doc'):
            doc_data['companion_doc'] = rewrite_companion_links(
                doc_data['companion_doc'],
                companion_path,
                by_companion_path,
                by_stem,
            )

        layer_adoc = layer_template.render(layer=doc_data)
        write_text(layer_dir / f'{layer_name}.adoc', layer_adoc)

        layers_info.append({
            'name': layer_name,
            'description': doc_data['layer_info'].get('description', 'No description'),
            'category': doc_data['layer_info'].get('category', 'uncategorised'),
        })

    layer_index_source = docs_dir / 'layer' / 'index.adoc'
    layer_index_content = rewrite_static_site_links(layer_index_source.read_text(encoding='utf-8'))
    layer_index = env.get_template('layer-index.adoc.j2').render(
        content=layer_index_content,
        layers=layers_info,
    )
    write_text(layer_dir / 'index.adoc', layer_index)

    validation_data = get_validator_documentation_data()
    validation_adoc = env.get_template('variable-validation.adoc.j2').render(
        validation=validation_data,
    )
    write_text(layer_dir / 'variable-validation.adoc', validation_adoc)

    print(f'\nDocusaurus AsciiDoc generated in {output_dir}/')


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description='Generate Docusaurus documentation input.')
    parser.add_argument(
        '--output-dir',
        default=str(script_dir / 'generated-docs'),
        help='output directory for generated Docusaurus input; default: website/generated-docs',
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    generate_docusaurus_docs(Path(args.output_dir))


if __name__ == '__main__':
    main()
