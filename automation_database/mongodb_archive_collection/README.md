# Mongodb clean collection
### Skills summary:
- **#python3**
- **#mongodb**

### Requirements
- ENVIRONMENT
- MONGO_PRIMARY
- MONGO_SECONDARY
- MONGO_DB
- MONGO_COLLECTION
- ARCHIVE_START_DATE
- ARCHIVE_FINISH_DATE
- DELETE_CONFIRM (Yes/No)

### Description:
Script `archive_mongo_collection.py`:
1. Check data for 1 day.
2. Create archive for requested data in json format.
3. Upload archive file into AWS S3 if not exist.
4. If DELETE_CONFIRM=Yes, delete data from collection with chunk 10000.

### Output example:
```
=== Working range: 2022-01-07 - 2022-01-08
TOTAL COUNT OF DOCS: 2109 STATES
SENDING DUMP PP_stateJournal_2022-01-07.json.gz TO S3 PP/mongo_archive/stateJournal/2022-01/PP_stateJournal_2022-01-07.json.gz
Deleting docs from collection
TOTAL COUNT OF DOCS: 1109 STATES
Deleting docs from collection
TOTAL COUNT OF DOCS: 109 STATES
Deleting docs from collection
TOTAL COUNT OF DOCS: 0 STATES
All docs were removed
```
### Check manually:
```
was: gameiom  652.948GB
Filesystem               Size  Used Avail Use% Mounted on
/dev/mapper/centos-root  744G  661G   84G  89% /

> db.archive_stateJournal.drop()
now: gameiom  577.941GB
Filesystem               Size  Used Avail Use% Mounted on
/dev/mapper/centos-root  744G  587G  158G  79% /
```
