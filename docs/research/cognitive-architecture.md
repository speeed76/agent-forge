# Cognitive Architecture for LLM Agents

Research stream 1 of 3. Focus: How cognitive science frameworks map to LLM agent memory and context management.

## Key Frameworks

### CoALA — Cognitive Architectures for Language Agents
- **Authors:** Sumers, Yao, Narasimhan, Griffiths (2023; TMLR 2024)
- **Paper:** [arXiv:2309.02427](https://arxiv.org/abs/2309.02427)
- **Core model:** Working Memory (context window) + Long-Term Memory (semantic/episodic/procedural)
- **Key insight:** Most agent systems only implement semantic LTM. Episodic (incidents) and procedural (workflows) are missing.

### Generative Agents (Stanford/Google)
- **Authors:** Park, O'Brien, Cai, Morris, Liang, Bernstein (2023; UIST 2023)
- **Paper:** [arXiv:2304.03442](https://arxiv.org/abs/2304.03442)
- **Core mechanism:** Memory stream with Observation → Reflection → Planning
- **Critical finding:** Removing reflection caused degeneration within 48 simulated hours
- **Retrieval:** Weighted combination of recency (decay), importance (1-10), relevance (embedding similarity)

### MemGPT / Letta
- **Authors:** Packer, Wooders, Lin, Fang, Patil, Gonzalez (UC Berkeley, 2023)
- **Paper:** [arXiv:2310.08560](https://arxiv.org/abs/2310.08560)
- **Core mechanism:** Context window as "RAM," external storage as "disk," LLM as "OS"
- **Memory operations:** `core_memory_append`, `core_memory_replace`, `archival_memory_insert/search`
- **Key for session persistence:** Core memory persists between sessions; archival memory searchable

### A-MEM — Agentic Memory
- **Authors:** Xu, Liang, Mei, Gao, Tan, Zhang (2025; NeurIPS 2025)
- **Paper:** [arXiv:2502.12110](https://arxiv.org/abs/2502.12110)
- **Core mechanism:** Zettelkasten-style linked notes — graph of memories with explicit relationships
- **Key advantage:** Cross-referencing captures what flat memory stores miss

### HiAgent — Hierarchical Working Memory
- **Paper:** [arXiv:2408.09559](https://arxiv.org/abs/2408.09559) (ACL 2025)
- **Core mechanism:** Subgoals as memory chunks. Complete subgoal → summarize → replace detailed observations
- **Result:** 2x success rate increase on long-horizon tasks

### MACLA — Hierarchical Procedural Memory
- **Paper:** [arXiv:2512.18950](https://arxiv.org/abs/2512.18950)
- **Core mechanism:** Extract reusable procedures from trajectories, track reliability via Bayesian posteriors
- **Result:** 2,851 trajectories → 187 procedures. 56 seconds construction (2,800x faster than fine-tuning)

### Episodic Memory Position Paper
- **Authors:** Pink et al. (2025)
- **Paper:** [arXiv:2502.06975](https://arxiv.org/abs/2502.06975)
- **Core argument:** Current agents have semantic + some procedural memory but almost no episodic
- **Five properties of episodic memory:** unique events, temporal context, autonoetic consciousness, reliving, flexible retrieval

### SOAR
- **Author:** Laird (1987, continuously developed)
- **Core mechanism:** Chunking — when impasse encountered, drops to subgoal, resolves, compiles resolution into production rule
- **LLM adaptation (CogRec, 2024):** SOAR hits impasse → queries LLM → transforms solution into symbolic rule

### ACT-R
- **Author:** Anderson (1993, continuously developed)
- **Core mechanism:** Activation-based memory retrieval with decay + spreading activation
- **LLM adaptation (LLM-ACTR, 2024):** [arXiv:2408.09176](https://arxiv.org/abs/2408.09176)

## Context Compression

### LLMLingua (Microsoft, 2023)
- [arXiv:2310.05736](https://arxiv.org/abs/2310.05736)
- Up to 20x compression with ~1.5 point performance drop
- **Critical limitation for code:** Token-level compression is wrong abstraction for code understanding. Need semantic-level compression.

### Seven Failure Points of RAG (Barnett et al., 2024)
- [arXiv:2401.05856](https://arxiv.org/abs/2401.05856)
- Embedding similarity does not capture behavioral interaction between code components
- Cross-file behavior is emergent — no single chunk contains the full picture

### GraphRAG (Microsoft, 2024)
- [arXiv:2404.16130](https://arxiv.org/abs/2404.16130)
- Entity knowledge graph → community detection → community summaries → community-level retrieval
- Captures relational structure that flat embeddings miss

## Synthesis

### Tier 1 Intervention: Behavioral Summaries (Reflection)
Converting verbose source files into dense operational semantics documents. This is Park et al.'s reflection mechanism applied to code. No infrastructure required — only discipline.

### Three Memory Types for Code Projects

| Type | What | Storage Mechanism |
|------|------|-------------------|
| Semantic | Facts, concepts, relationships | CLAUDE.md, rule files |
| Episodic | Time-stamped experiences, incidents | MEMORY.md incident records |
| Procedural | Executable workflows | Commands, session protocols |
