# Mongodb clean state
### Skills summary:
- **#python3**
- **#mongodb**
- **#mysqldb**

### Requirements
- MySQL credentials
- GAME_CYCLE_ID
- Ticket number

### Description:
Script `mongodb_clean_state.py`:
1. Find player`s state by GAME_CYCLE_ID
2. Clean state (example of request)
```
db.stateJournal.updateMany({'gameId':1,'providerId':48,'username':'user1','operatorId':1 },{$set: {'operatorId': -1}})
```
3. Inserts record to DB with results
4. Recheck if states are not present in DB

### Output example 48:aa4571dd-db85-489c-a2bb-c9075ab5818a:
```
=== COLLECTION OF STATES FOR '48:aa4571dd-db85-489c-a2bb-c9075ab5818a' GAME CYCLE:
# DATA ABOUT STATES
=== UPDATING STATES FOR '48:aa4571dd-db85-489c-a2bb-c9075ab5818a' GAME CYCLE:
=== db.stateJournal.updateMany({'gameId': 112, 'providerId': 48, 'username': 'ags_test_5', 'operatorId': 1}, {'$set': {'operatorId': '-1'}})
4 states updated.
*** Collecting information about cleaning process
*** Updating cleaned_rounds database
*** record(s) affected:  1
*** MySQL connection is closed
=== RESULTS ===
=== COLLECTION OF STATES FOR '48:aa4571dd-db85-489c-a2bb-c9075ab5818a' GAME CYCLE:
# DATA ABOUT STATES
```
