# Collaborating on a Shared Gist

## For the creator — sharing with a teammate

After `/gh-gist-sharing tmp/<your-dir>` creates the Gist, send your teammate this message (substituting the actual Gist ID):

---

I've shared `tmp/<dir-name>` as a Gist. Here's how to get in and contribute:

1. Fork the Gist so you have your own writable copy:
   ```
   gh gist fork <CREATOR_GIST_ID>
   ```
   Note the fork ID it prints.

2. Run the skill in your project to set everything up:
   ```
   /gh-gist-sharing https://gist.github.com/<CREATOR_GIST_ID>
   ```
   It will ask for your fork ID and which local directory to sync into.

3. To push your changes back: commit and push inside `tmp/.gist-clones/<your-fork-id>/`, then let me know your fork ID so I can pull your changes.

4. To pull my latest updates: run `/gh-gist-sharing https://gist.github.com/<CREATOR_GIST_ID>` again.

---

## For the collaborator — getting the creator's updates

To register your fork with the creator:
1. After forking, give the creator your fork's Gist ID.
2. The creator runs: `/gh-gist-sharing --add-collaborator <your-name> <your-fork-id>`
3. When the creator has merged your changes, run `/gh-gist-sharing https://gist.github.com/<CREATOR_GIST_ID>` to pull them back.

## For the creator — merging a teammate's changes

Once a collaborator has pushed changes to their fork:
```
/gh-gist-sharing --add-collaborator alice <ALICE_FORK_ID>   # one time only
/gh-gist-sharing --merge alice
```
