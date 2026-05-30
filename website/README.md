# rpi-image-gen website

This is the Docusaurus documentation site for `rpi-image-gen`.

The build keeps upstream compatibility by leaving the existing static HTML docs
flow intact. For Docusaurus, `website/generate.py` generates temporary AsciiDoc
reference pages under `website/generated-docs/`; that directory is ignored.

## Local development

```bash
cd website
python3 -m pip install -r requirements.txt
npm ci
npm run start
```

## Production build

```bash
cd website
npm run build
npm run serve -- --host 0.0.0.0
```

The `build` script automatically runs:

```bash
python3 generate.py --output-dir generated-docs
```

before `docusaurus build`.
