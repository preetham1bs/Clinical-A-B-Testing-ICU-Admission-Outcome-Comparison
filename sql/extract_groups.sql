
-- A/B testing MySQL extraction

USE mimic3;

SELECT
    a.hadm_id,
    a.subject_id,
    a.admission_type,

    -- Group label (your A/B groups)
    CASE
        WHEN a.admission_type = 'EMERGENCY' THEN 'Emergency'
        WHEN a.admission_type = 'ELECTIVE'  THEN 'Elective'
        ELSE NULL
    END                                         AS group_label,

    -- Outcome 1: Hospital length of stay (days)
    DATEDIFF(a.dischtime, a.admittime)          AS hosp_los_days,

    -- Outcome 2: In-hospital mortality (1=died, 0=survived)
    a.hospital_expire_flag                      AS died_in_hospital,

    -- Outcome 3: ICU duration (days) — NULL if no ICU stay
    i.total_icu_los,

    -- Covariates (for context / subgroup analysis)
    LEAST(
        TIMESTAMPDIFF(YEAR, p.dob, a.admittime), 91
    )                                           AS age,
    p.gender,
    a.insurance,
    a.diagnosis                                 AS primary_diagnosis

FROM admissions a
JOIN patients p
    ON a.subject_id = p.subject_id
LEFT JOIN (
    -- Aggregate ICU stays per admission
    SELECT hadm_id,
           ROUND(SUM(los), 2) AS total_icu_los
    FROM   icustays
    GROUP  BY hadm_id
) i ON a.hadm_id = i.hadm_id

WHERE a.admission_type IN ('EMERGENCY', 'ELECTIVE')
  AND a.dischtime IS NOT NULL
  AND DATEDIFF(a.dischtime, a.admittime) >= 0  -- remove bad records

ORDER BY a.admission_type, a.hadm_id;