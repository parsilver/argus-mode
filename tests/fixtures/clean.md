# Fixture: ordinary dev prose that must pass

Migrated the Oracle connection pool to HikariCP without downtime.

Switched traffic to the green environment after the smoke run.

Fan-out writes now batch to the replicas every 500 ms.

Tuned the WAL checkpoint interval; database checkpoint time halved.

The file explorer panel keeps its scroll position on reload.

Stage 2 of the rollout begins Monday; stage 3 depends on the audit.

Code review found two issues; both fixed and re-verified.

Plan revised once in design review before work started.
