/*Tables*/

CREATE TABLE if not EXISTS notes (uniqueID INTEGER UNIQUE NOT NULL PRIMARY KEY, truncatedText TEXT, links BLOB, sortDate DATE NOT NULL, thumbnailID TEXT, archived BOOLEAN NOT NULL DEFAULT 0, text TEXT, creationDate DATE NOT NULL, textModificationDate DATE, sortDateModificationDate DATE, archivedModificationDate DATE, tagsModificationDate DATE, attachmentsModificationDate DATE, modificationDate DATE);

CREATE TABLE if not EXISTS tags (uniqueID TEXT UNIQUE NOT NULL PRIMARY KEY, name TEXT UNIQUE NOT NULL, nameModificationDate DATE);

CREATE TABLE if not EXISTS attachments(uniqueID TEXT UNIQUE NOT NULL PRIMARY KEY, mimeType TEXT NOT NULL, height INTEGER, width INTEGER);

CREATE TABLE if not EXISTS deletedNotes (uniqueID INTEGER UNIQUE NOT NULL PRIMARY KEY);

/*Lookup tables*/

CREATE TABLE if not EXISTS tagsNotesLookup (tagID TEXT NOT NULL, noteID INTEGER NOT NULL, ix INTEGER NOT NULL, PRIMARY KEY(tagID, noteID));

CREATE TABLE if not EXISTS attachmentsNotesLookup (attachmentID TEXT NOT NULL, noteID INTEGER NOT NULL, ix INTEGER NOT NULL, PRIMARY KEY(attachmentID, noteID));

/*Indexes*/

CREATE INDEX if not EXISTS archivedIndex on notes (archived);

CREATE INDEX if not EXISTS sortDateIndex on notes (sortDate);

CREATE INDEX if not EXISTS modificationDateIndex on notes (modificationDate);

CREATE INDEX if not EXISTS tagsNoteIDIndex on tagsNotesLookup (noteID);

CREATE INDEX if not EXISTS attachmentsNoteIDIndex on attachmentsNotesLookup (noteID);
