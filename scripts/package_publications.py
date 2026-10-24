"""Package the author's archived replication files for the Quarto website.

Usage: python scripts/package_publications.py --source-root PATH
Requires pandas and numpy. Source files are read only. No network access.
"""
from __future__ import annotations
import argparse
import csv
import hashlib
import io
import json
from pathlib import Path
import zipfile
import numpy as np
import pandas as pd

EUP_BASE = 'Articles_Final_Submission_All_4_Papers/Switching and Weak Institutionalization/EUP Submission/R&R2/Submission Files/Replication Files'
PP_BASE = 'Articles_Final_Submission_All_4_Papers/stata_analysis_ambitious_switch/Analysis for Party Politics Submission/Final_Models_Apps'
DATA = {
    'eup': ['EUP_replication_dataset_12092020_2.csv', 'EUP_replication_dataset_12092020_A_2.csv', 'EUP_replication_dataset_12092020_B_3.csv', 'EUP_replication_dataset_12092020_C_2.csv', 'EUP_replication_dataset_12092020_D_2.csv', 'McElroy_replication_data.csv', 'McElroy_replication_data_2.csv'],
    'party-politics': ['dataset_12222020.csv', 'PP_dataset.csv'],
}
ARCHIVE_FILES = {
    'eup': (EUP_BASE, ['EUP_replication_dataset_12092020.dta', 'McElroy_replication_data.dta', 'Replication_Code_12102020.do', 'replication_log.log', 'Figure2.gph']),
    'party-politics': (PP_BASE, ['dataset_12222020.dta', 'PP_dataset.dta', 'PP_20210325.do', 'march25_2021.log']),
}
VERSION = {
    'eup': 'The Python port covers the data construction and selected statistical tables from the December 2020 replication files. Its saved reports do not establish complete reproduction of every published figure, table or appendix. See the included README and saved validation reports for scope and tolerances.',
    'party-politics': 'IMPORTANT VERSION NOTE: this is the archived March 25, 2021 analysis and its later Python port. The final published article (2022 online; 2023 journal issue) reports Firth penalized logistic regression in Table 4. The archived README refers to earlier multilevel Tables 4/5; those descriptions must not be read as a verified replication of the final published paper. The saved checks cover data construction and three archived Firth models. No full final-publication replication is claimed.',
}

def sha(raw):
    return hashlib.sha256(raw).hexdigest()

def validate_csv(csv_path, stata_path):
    text = pd.read_csv(csv_path, low_memory=False, keep_default_na=False)
    with pd.io.stata.StataReader(stata_path, convert_categoricals=False) as reader:
        data = reader.read()
        variable_labels = reader.variable_labels()
        value_labels = reader.value_labels()
    if text.shape != data.shape or list(text) != list(data):
        raise ValueError(f'Shape/column mismatch: {csv_path.name}')
    for col in data:
        left, right = text[col], data[col]
        if pd.api.types.is_datetime64_any_dtype(right):
            equal = pd.to_datetime(left.replace('', None)).equals(right)
        elif pd.api.types.is_numeric_dtype(right):
            left = pd.to_numeric(left.replace('', np.nan), errors='raise')
            equal = np.allclose(left.to_numpy(dtype=float), right.to_numpy(dtype=float), rtol=1e-6, atol=1e-8, equal_nan=True)
        else:
            equal = left.fillna('').astype(str).equals(right.fillna('').astype(str))
        if not equal:
            raise ValueError(f'Value mismatch: {csv_path.name}: {col}')
    return {
        'csv': csv_path.name, 'rows': len(data), 'columns': len(data.columns),
        'verification': 'All cells compared with source Stata file; numeric rtol=1e-6, atol=1e-8; dates parsed before comparison.',
        'variables': {name: {'label': variable_labels.get(name, ''), 'pandas_dtype': str(data[name].dtype)} for name in data},
        'stata_value_label_definitions': value_labels,
        'notes': 'CSV does not embed Stata variable/value labels or storage types. Numeric category codes are retained. Empty fields represent missing values; extended Stata missing-value distinctions are not retained in CSV. Original .dta files remain authoritative for Stata metadata.',
    }

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source-root', type=Path, required=True)
    args = parser.parse_args()
    source = args.source_root.resolve()
    dest = Path(__file__).resolve().parents[1] / 'publications' / 'downloads'
    manifest_rows = list(csv.DictReader((source / 'Converted Data Files/_manifest.csv').open(encoding='utf-8-sig')))
    mapping = {r['output_file']: r['original_path'] for r in manifest_rows}
    summary = []
    for paper, names in DATA.items():
        out = dest / paper
        out.mkdir(parents=True, exist_ok=True)
        originals = {}
        base, files = ARCHIVE_FILES[paper]
        for name in files:
            originals[name] = (source / base / name).read_bytes()
        python_files = {}
        provenance = []
        metadata = {}
        for name in names:
            path = source / 'Converted Data Files' / name
            metadata[name] = validate_csv(path, source / mapping[name])
            raw = path.read_bytes()
            (out / name).write_bytes(raw)
            python_files['Converted Data Files/' + name] = raw
            provenance.append({'csv': name, 'source_stata_path': mapping[name], 'csv_sha256': sha(raw), 'stata_sha256': sha((source / mapping[name]).read_bytes()), 'rows': metadata[name]['rows'], 'columns': metadata[name]['columns']})
        package = 'EUP_Python_Replication' if paper == 'eup' else 'PP_Python_Replication'
        for path in sorted((source / package).rglob('*')):
            if path.is_file() and '__pycache__' not in path.parts and path.suffix in {'.py', '.R', '.md', '.csv'}:
                relative = path.relative_to(source).as_posix()
                raw = path.read_bytes()
                if path.name == 'README.md' and path.parent.name == package:
                    raw = ('> ' + VERSION[paper] + '\n\n').encode() + raw
                if path.name == 'config.py':
                    config_text = raw.decode()
                    if paper == 'eup':
                        config_text = config_text[:config_text.index('LOG_FILE =')] + 'LOG_FILE = DATA / \"reference\" / \"replication_log.log\"\n' + config_text[config_text.index('OUT ='):]
                    else:
                        config_text = config_text[:config_text.index('BASE =')] + 'BASE = DATA / \"reference\"\n' + config_text[config_text.index('DO_FILE'): ]
                    raw = config_text.encode()
                python_files[relative] = raw
        log = 'replication_log.log' if paper == 'eup' else 'march25_2021.log'
        python_files['reference/' + log] = originals[log]
        do_file = 'Replication_Code_12102020.do' if paper == 'eup' else 'PP_20210325.do'
        python_files['reference/' + do_file] = originals[do_file]
        (out / do_file).write_bytes(originals[do_file])
        for report in sorted((source / package / 'output').glob('*.md')):
            (out / ('_' + report.name)).write_bytes(report.read_bytes())
        codebook = (json.dumps(metadata, ensure_ascii=False, indent=2, default=str) + '\n').encode()
        (out / 'codebooks.json').write_bytes(codebook)
        python_files['codebooks.json'] = codebook
        csv_manifest = io.StringIO(newline='')
        writer = csv.DictWriter(csv_manifest, fieldnames=list(provenance[0]))
        writer.writeheader(); writer.writerows(provenance)
        (out / 'data-manifest.csv').write_text(csv_manifest.getvalue(), encoding='utf-8', newline='')
        python_files['data-manifest.csv'] = csv_manifest.getvalue().encode()
        notes = f'''# Replication materials: {paper}\n\n{VERSION[paper]}\n\n## Run the Python package\n\nExtract the whole ZIP, retaining the directory structure. Python 3.10+ is recommended. From the extracted directory:\n\n    python -m venv .venv\n    # Activate the environment using the command for your operating system.\n    python -m pip install -r requirements.txt\n    cd {package}\n    python run_all.py\n\nThe bundled config paths point to reference/ for the original do-file and log; analysis code is unchanged. Read {package}/README.md for additional validation commands and omissions. Existing output files and reports are historical results supplied with the port; they were not regenerated when packaging the downloads. The Party Politics R script needs R and lme4 and is not a verified final-publication replication.\n\n## Data\n\nCSV copies are unchanged from the author's converted-data folder. data-manifest.csv records the corresponding source Stata path, dimensions and SHA-256 digests. codebooks.json preserves variable labels and value-label definitions read from those originals. CSVs retain numeric category codes. Empty fields represent missing values; CSV does not preserve all Stata metadata or extended missing codes. Load using pandas.read_csv; Stata is not required. Treat identifiers as identifiers rather than measurements.\n\nSome original Stata strings trigger pandas' documented UTF-8 to Latin-1 decoding fallback. The CSVs were compared to those decoded originals, including date and string values.\n\n## Original Stata materials\n\nThe separate Stata ZIP contains archived .dta, .do and log files. The original code is unchanged and may need working-directory paths and Stata add-on commands configured. The March 2021 Party Politics archive is not certified as the final published replication package.\n\n## Citation and reuse\n\nPlease cite Aaron R. Martin's corresponding article (DOI below) when using these materials and retain attribution to underlying data sources. No new blanket licence is assigned here to third-party inputs; see the article, original documentation and source conditions for their terms.\n\nDOI: {'10.1177/1465116521999718' if paper == 'eup' else '10.1177/13540688221096531'}\n'''
        python_files['README.md'] = notes.encode()
        python_files['requirements.txt'] = b'pandas>=2.2,<3\nnumpy>=1.26,<3\nscipy>=1.12,<2\nstatsmodels>=0.14,<1\n'
        for kind, entries in [('stata', originals), ('python', python_files)]:
            if kind == 'stata':
                entries = dict(entries, **{'README.md': notes.encode()})
            archive = out / f'{paper}-{kind}.zip'
            with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED, compresslevel=9) as z:
                for name, raw in sorted(entries.items()):
                    info = zipfile.ZipInfo(name, date_time=(2026, 10, 24, 0, 0, 0))
                    info.compress_type = zipfile.ZIP_DEFLATED
                    z.writestr(info, raw)
            with zipfile.ZipFile(archive) as z:
                assert z.testzip() is None
            summary.append({'file': archive.relative_to(dest).as_posix(), 'bytes': archive.stat().st_size, 'sha256': sha(archive.read_bytes())})
        print(paper, 'CSV verification passed:', [(x['csv'], x['rows'], x['columns']) for x in provenance])
    (dest / 'checksums.json').write_text(json.dumps(summary, indent=2) + '\n', encoding='utf-8')
    print(json.dumps(summary, indent=2))

if __name__ == '__main__':
    main()
