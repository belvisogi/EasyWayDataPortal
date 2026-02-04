---
title: Database Architecture Master
chapter: 01
tags: [database, architettura, multi-tenant, ams, chatbot, conversational, portal, gold, bronze, rls, masking, stored-procedure, sequence, domain/db, layer/spec, audience/dev, audience/dba, privacy/internal, language/it]
source: easyway-webapp/01-database-architecture.md
id: ew-01-database-architecture
llm:
  pii: none
  include: true
  chunk_hint: 400-600
  redaction: [email, phone]
entities: []
summary: Master document per l'architettura del database EasyWay: schema multitenant, integrazione AMS/Chatbot, naming convention e security (RLS, masking).
status: active
owner: team-platform
updated: '2026-01-16'
next: Aggiornare diagramma ERD.
type: guide
---
[Home](./start-here.md) > [[domains/db|db]] > 

# EasyWay Data Portal - Database Architecture Master

> **Modello in uso:** Nexus Multi-Tenant (anagrafiche larghe, surrogate key INT, NDG univoche, ext_attributes, RLS, auditing).
> **Conversational Intelligence & AMS ready**: tutte le procedure, tabelle, funzioni e documentazione sono progettate per essere governate anche via chatbot, automation, agent e AMS.
---






