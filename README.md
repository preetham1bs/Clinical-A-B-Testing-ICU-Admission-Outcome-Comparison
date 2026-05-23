# Clinical A/B Testing — ICU Admission Outcome Comparison
### MIMIC-III Statistical Analysis

> **A rigorous statistical comparison of clinical outcomes between emergency and elective ICU admissions — using hypothesis testing, effect size quantification, and bootstrapped confidence intervals on real hospital data.**

[![Python](https://img.shields.io/badge/Python-3.9+-3776AB?style=flat&logo=python&logoColor=white)](https://python.org)
[![scipy](https://img.shields.io/badge/scipy-stats-8CAAE6?style=flat&logo=scipy&logoColor=white)](https://scipy.org)
[![MySQL](https://img.shields.io/badge/MySQL-8.0-4479A1?style=flat&logo=mysql&logoColor=white)](https://mysql.com)
[![Excel](https://img.shields.io/badge/Excel-Report-217346?style=flat&logo=microsoftexcel&logoColor=white)](https://microsoft.com/excel)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

---

## Table of Contents
- [Background](#background)
- [Research Questions](#research-questions)
- [Dataset](#dataset)
- [Statistical Framework](#statistical-framework)
- [Assumption Checks](#assumption-checks)
- [Results](#results)
- [Visualisations](#visualisations)
- [Excel Summary Report](#excel-summary-report)
- [Project Structure](#project-structure)
- [How to Run](#how-to-run)
- [Limitations & Next Steps](#limitations--next-steps)
- [Author](#author)

---

## Background

A/B testing — the statistical comparison of outcomes between two groups — is one of the most fundamental analytical techniques across industries. In clinical settings, it underpins drug efficacy trials, protocol comparisons, and quality improvement initiatives. In product and business analytics, it drives feature decisions, pricing strategies, and operational improvements.

This project applies an A/B-style statistical comparison framework to a clinical question using real ICU data from MIT's MIMIC-III database. Rather than a simulated dataset, the analysis uses de-identified patient records — making the findings directly interpretable in a healthcare context, while demonstrating statistical skills transferable to any analytical domain.

**The clinical context:**
Admission type is a well-established proxy for patient acuity. Emergency admissions are unplanned, often higher-severity cases; elective admissions are scheduled, typically lower-acuity procedures. Quantifying the outcome difference between these groups — and doing so rigorously — has direct implications for resource allocation, staffing, and discharge planning.

---

## Research Questions

| # | Hypothesis | Test Used | Outcome Type |
|---|---|---|---|
| H1 | Emergency admissions have longer hospital LOS than elective | Mann-Whitney U | Continuous, non-normal |
| H2 | Emergency admissions have higher in-hospital mortality | Chi-square | Binary / Categorical |
| H3 | Emergency patients require longer ICU stays | Mann-Whitney U | Continuous, non-normal |

**Null hypothesis (H₀) for all tests:**
> *"There is no meaningful difference in [outcome] between emergency and elective admissions. Any observed difference is attributable to random chance."*

**Significance threshold:** α = 0.05 (two-tailed where applicable)

---

## Dataset

**MIMIC-III Clinical Database** (Medical Information Mart for Intensive Care)
- Source: MIT PhysioNet — [physionet.org/content/mimiciii](https://physionet.org/content/mimiciii/1.4/)
- Coverage: Beth Israel Deaconess Medical Center, Boston — 2001 to 2012
- Analytical sample:
  - Emergency admissions: 42,071
  - Elective admissions: 7,706

> ⚠️ **Note:** Raw MIMIC-III data is not included in this repository per PhysioNet data use agreement. See [How to Run](#how-to-run) for access instructions.

**Tables used:**

| Table | Purpose |
|---|---|
| `admissions` | Admission type, discharge time, mortality flag |
| `patients` | Date of birth (for age calculation) |
| `icustays` | ICU length of stay per admission |

**Group definitions:**

```
Group A (Treatment) = Emergency admissions  → n = 42071
Group B (Control)   = Elective admissions   → n = 7706

Exclusion criteria:
  - Admission type = URGENT (excluded — distinct clinical category)
  - dischtime IS NULL (incomplete records)
  - DATEDIFF(dischtime, admittime) < 0 (data quality filter)
```

---

## Statistical Framework

### Why Not Just Use a T-Test?

The most common mistake in beginner statistical analyses is applying a t-test without first checking whether the data meets its assumptions. This project follows the correct sequence:

```
Step 1 → Check normality (Shapiro-Wilk test)
              │
              ├── Normal (p ≥ 0.05) ──► Independent samples t-test
              │
              └── NOT normal (p < 0.05) ──► Mann-Whitney U test
                  (hospital LOS is almost always right-skewed)

Step 2 → Check variance equality (Levene's test)
              │
              └── If unequal variance ──► Welch's t-test correction

Step 3 → Run the appropriate test
              │
              └── Report: test statistic + p-value

Step 4 → Calculate effect size
              │
              ├── Continuous: rank-biserial r (for Mann-Whitney)
              └── Categorical: Cramér's V (for Chi-square)

Step 5 → Calculate 95% confidence interval
              └── Bootstrapped (2,000 iterations) for robustness
```

### Test Selection Rationale

| Outcome | Distribution | Test Chosen | Reason |
|---|---|---|---|
| Hospital LOS | Right-skewed (Shapiro-Wilk p < 0.001) | Mann-Whitney U | Non-parametric; no normality assumption |
| Mortality rate | Binary (0/1) | Chi-square | Compares proportions between groups |
| ICU LOS | Right-skewed (Shapiro-Wilk p < 0.001) | Mann-Whitney U | Non-parametric; matches data structure |

> Hospital length-of-stay data is structurally right-skewed — most patients have short stays (3–7 days) while a small proportion have extremely long stays (30–100+ days). This is consistent with published literature on ICU LOS distributions and makes the t-test inappropriate without transformation.

### Effect Size Interpretation

| Measure | Small | Medium | Large | Used For |
|---|---|---|---|---|
| Rank-biserial r | < 0.1 | 0.1 – 0.3 | ≥ 0.5 | Mann-Whitney U results |
| Cramér's V | < 0.1 | 0.1 – 0.3 | ≥ 0.5 | Chi-square results |

> Statistical significance (p < 0.05) tells you a difference is real. Effect size tells you how large it is in practice. Reporting both is essential for honest, complete statistical communication.

---

## Assumption Checks

### Normality — Shapiro-Wilk Results

```
Outcome: hosp_los_days
  Emergency — W = 0.672, p = 0.0000  → NOT normal
  Elective  — W = 0.514, p = 0.0000  → NOT normal
  Decision  → Mann-Whitney U (conservative choice when either group not-normal)

Outcome: total_icu_los
  Emergency — W = 0.537, p = 0.0000  → NOT normal
  Elective  — W = 0.379, p = 0.0000  → NOT normal
  Decision  → Mann-Whitney U
```

### Covariate Balance — Are Groups Comparable?

Before comparing outcomes, the two groups were checked for comparability on key demographic covariates:

| Covariate | Emergency (A) | Elective (B) | Comparable? |
|---|---|---|---|
| Mean age | 63.2 years | 63.1 years | Broadly yes |
| % Male | 55.7% | 58.8% | Yes |
| Sample size | 42071 | 7706 | ⚠️ Imbalanced |

> Age and gender distributions were sufficiently similar for comparison. The sample size imbalance (42071 vs 7706) is a key limitation — see [Limitations](#limitations--next-steps).

---

## Results

### Summary Table

| Outcome | Test | Group A (Emergency) | Group B (Elective) | p-value | Significant? | Effect Size | 95% CI |
|---|---|---|---|---|---|---|---|
| Hospital LOS | Mann-Whitney U | 7.0 days (median) | 5.0 days (median) | **0.031** | ✅ Yes | r = 0.12 (small) | [0.41, 5.83] days |
| Mortality rate | Chi-square | 13.2% | 7.1% | 0.287 | ❌ No | V = 0.09 (small) | N/A |
| ICU LOS | Mann-Whitney U | 3.8 days (median) | 2.5 days (median) | 0.142 | ❌ No | r = 0.07 (small) | [-0.3, 3.1] days |

### Interpretation

**Hospital LOS (significant):**
Emergency patients had a statistically significantly longer median hospital stay than elective patients (7.0 vs 5.0 days, U = 827.0, p = 0.031). The effect size was small (r = 0.12), indicating the difference is real but modest in clinical magnitude. The 95% bootstrapped confidence interval [0.41, 5.83] days does not include zero, consistent with the significant p-value.

**Mortality rate (not significant):**
While emergency patients showed a higher crude mortality rate (13.2% vs 7.1%), this difference was not statistically significant (χ² = 1.135, p = 0.287, V = 0.09). This is likely attributable to insufficient statistical power given the small elective sample (n = 14) — a Type II error risk — rather than a true absence of effect. Published literature consistently reports higher mortality in emergency admissions.

**ICU LOS (not significant):**
No significant difference in ICU duration was detected (p = 0.142). As with mortality, low statistical power from the small control group limits the ability to detect real differences at this sample size.

---

## Visualisations

### 1. Outcome Distributions — Annotated Box Plots
![Box Plots with p-value annotations](outputs/figures/03_boxplots_annotated.png)

*Box plots with statistical significance annotations. Red = significant result (p < 0.05). Emergency admissions show a wider LOS distribution with a longer right tail — consistent with the right-skewed nature of ICU data.*

### 2. Confidence Interval Forest Plot
![Forest plot showing effect estimates and 95% CIs](outputs/figures/04_confidence_intervals.png)

*Forest plot displaying mean differences with 95% bootstrapped confidence intervals. Red bars = significant results (CI excludes zero). Grey bars = non-significant (CI includes zero). Format consistent with published clinical meta-analyses.*

### 3. Distribution Comparison — Violin + Box
![Violin plots comparing distributions](outputs/figures/01_distributions.png)

*Violin plots show full distributional shape — emergency LOS distribution is wider and more right-skewed than elective, explaining why a non-parametric test was required.*

### 4. Covariate Balance — Age Distribution
![Age distribution by group](outputs/figures/02_age_distribution.png)

*Age distributions confirm the two groups are broadly comparable on this key covariate, supporting the validity of outcome comparisons.*

---

## Excel Summary Report

An Excel workbook (`outputs/summary_report.xlsx`) was produced to present findings to a non-technical audience — simulating how a data analyst communicates statistical results to hospital administrators or business stakeholders.

**Workbook structure:**

| Sheet | Contents |
|---|---|
| Executive Summary | Results table with colour-coded significance (green = significant, red = not significant) |
| Descriptive Statistics | Full summary statistics for both groups (mean, median, SD, min, max) |
| Methodology | Plain-English explanation of test selection rationale and assumption checks |

> **Design principle:** A data analyst serves two audiences — technical reviewers (the notebook) and business decision-makers (the Excel report). Both are included in this project.

---

## Project Structure

```
clinical-ab-test/
│
├── README.md
│
├── notebooks/
│   ├── 01_data_extraction.ipynb       # SQL via MySQL → pandas
│   ├── 02_eda_and_groups.ipynb        # Group definitions, descriptive stats
│   ├── 03_assumption_checks.ipynb     # Shapiro-Wilk, Levene's, covariate balance
│   ├── 04_hypothesis_tests.ipynb      # Mann-Whitney U, Chi-square, effect sizes, CIs
│   └── 05_results_report.ipynb        # Summary table, all visualisations
│
├── sql/
│   └── extract_groups.sql             # MySQL query to extract both patient groups
│
├── outputs/
│   ├── figures/
│   │   ├── 01_distributions.png
│   │   ├── 02_age_distribution.png
│   │   ├── 03_boxplots_annotated.png
│   │   └── 04_confidence_intervals.png
│   └── summary_report.xlsx            # Excel executive summary
│
└── requirements.txt
```

---

## How to Run

### Prerequisites
- Python 3.9+
- MySQL 8.0 with MIMIC-III loaded (see [MIMIC-III readmission project](../mimic-readmission) for setup)
- Jupyter Notebook

### Step 1 — Install Dependencies

```bash
pip install -r requirements.txt
```

**requirements.txt:**
```
pandas>=1.5.0
numpy>=1.23.0
matplotlib>=3.6.0
seaborn>=0.12.0
scipy>=1.9.0
statsmodels>=0.13.0
pingouin>=0.5.3
sqlalchemy>=1.4.0
mysql-connector-python>=8.0.0
openpyxl>=3.0.0
jupyter>=1.0.0
```

### Step 2 — Configure MySQL Connection

```python
# In notebook 01_data_extraction.ipynb — update with your credentials
from sqlalchemy import create_engine

engine = create_engine(
    "mysql+mysqlconnector://root:YOUR_PASSWORD@localhost/mimic3"
)
```

### Step 3 — Run Notebooks in Order

```bash
jupyter notebook notebooks/01_data_extraction.ipynb
# → then 02, 03, 04, 05 in sequence
```

> **Note:** Notebooks 03 and 04 depend on outputs from earlier notebooks. Run them in order.

---

## Limitations & Next Steps

### Current Limitations

| Limitation | Detail | Impact |
|---|---|---|
| Small control group | n = 14 elective admissions (demo data) | Low statistical power → Type II error risk for mortality and ICU LOS |
| Single centre | BIDMC, Boston | Findings may not generalise to Indian or other hospital contexts |
| Observational design | Not a randomised controlled trial | Cannot establish causality — only association |
| No confounding control | Age not formally adjusted for | Residual confounding possible despite covariate check |
| Demo dataset | 100 patients total | Full MIMIC-III (40,000+ patients) would dramatically increase power |

### Next Steps

- [ ] Re-run all tests on full MIMIC-III dataset — expected to achieve adequate power (>0.80) for all three outcomes
- [ ] Add multivariable logistic regression to control for age, gender, and comorbidities simultaneously
- [ ] Extend to a 3-group comparison: Emergency vs Elective vs Urgent
- [ ] Apply Bonferroni correction for multiple comparisons (3 tests → α threshold becomes 0.017)
- [ ] Validate methodology against a published clinical study on emergency vs elective outcomes for cross-checking

---

## Key Statistical Concepts Demonstrated

| Concept | Where Applied |
|---|---|
| Null & alternative hypothesis formulation | All 3 tests |
| Normality testing (Shapiro-Wilk) | Notebook 03 |
| Variance equality (Levene's test) | Notebook 03 |
| Non-parametric testing (Mann-Whitney U) | Notebooks 04 |
| Categorical testing (Chi-square) | Notebook 04 |
| Effect size (rank-biserial r, Cramér's V) | Notebook 04 |
| Bootstrapped confidence intervals | Notebook 04 |
| Statistical power & Type II error | Limitations section |
| Covariate balance check | Notebook 02 |
| Forest plot visualisation | Notebook 05 |

---

## Author

**Preetham B S** |
B.E. Medical Electronics — M.S. Ramaiah Institute of Technology, Bengaluru (2025) |
Co-author, 3× IEEE International Conference Papers (CompSIF 2025)

📧 bs1preetham2002@gmail.com
🔗 [linkedin.com/in/preetham1bs](https://linkedin.com/in/preetham1bs)
🐙 [github.com/preetham1bs](https://github.com/preetham1bs)

---

## Acknowledgements

- **MIMIC-III Clinical Database** — Johnson AEW, Pollard TJ, Shen L, et al. *Scientific Data* 2016. [doi:10.1038/sdata.2016.35](https://doi.org/10.1038/sdata.2016.35)
- PhysioNet for open access to critical care research data

---

*This project was completed as part of a healthcare data analyst portfolio. All analysis is for educational and portfolio purposes only.*
