import 'package:seminary_sidekick/models/scripture.dart';
import 'package:seminary_sidekick/models/enums.dart';

/// A small set of scriptures for testing. Don't use allScriptures in tests —
/// it's 100 entries and makes assertions noisy.
final testScriptures = [
  Scripture(
    id: 'test-1',
    book: ScriptureBook.bookOfMormon,
    volume: '1 Nephi',
    reference: '1 Nephi 3:7',
    name: 'Obedience to Commandments',
    keyPhrase: 'I will go and do',
    fullText:
        'And it came to pass that I Nephi said unto my father I will go and do the things which the Lord hath commanded',
  ),
  Scripture(
    id: 'test-2',
    book: ScriptureBook.newTestament,
    volume: 'John',
    reference: 'John 3:16',
    name: 'God So Loved the World',
    keyPhrase: 'For God so loved the world',
    fullText:
        'For God so loved the world that he gave his only begotten Son that whosoever believeth in him should not perish but have everlasting life',
  ),
  Scripture(
    id: 'test-3',
    book: ScriptureBook.oldTestament,
    volume: 'Proverbs',
    reference: 'Proverbs 3:5-6',
    name: 'Trust in the Lord',
    keyPhrase: 'Trust in the Lord with all thine heart',
    fullText:
        'Trust in the Lord with all thine heart and lean not unto thine own understanding',
  ),
  Scripture(
    id: 'test-4',
    book: ScriptureBook.doctrineAndCovenants,
    volume: 'D&C',
    reference: 'D&C 58:27',
    name: 'Anxiously Engaged',
    keyPhrase: 'Anxiously engaged in a good cause',
    fullText:
        'Verily I say men should be anxiously engaged in a good cause and do many things of their own free will',
  ),
  // 5th scripture for tests that need > 4 scriptures
  Scripture(
    id: 'test-5',
    book: ScriptureBook.bookOfMormon,
    volume: 'Moroni',
    reference: 'Moroni 10:4-5',
    name: 'Promise of the Book of Mormon',
    keyPhrase: 'Ask with a sincere heart',
    fullText:
        'And when ye shall receive these things I would exhort you that ye would ask God the Eternal Father in the name of Christ if these things are not true',
  ),
  // Multi-verse fixture for verse-gated Scripture Builder (TASK-076)
  Scripture(
    id: 'test-multi-verse',
    book: ScriptureBook.oldTestament,
    volume: 'Abraham',
    reference: 'Abraham 2:9–11',
    name: 'Multi-verse fixture',
    keyPhrase: 'bear this ministry',
    fullText:
        'And I will make of thee a great nation; And I will bless them through thy name; And I will bless them that bless thee.',
    verses: const [
      'And I will make of thee a great nation;',
      'And I will bless them through thy name;',
      'And I will bless them that bless thee.',
    ],
  ),
];

/// Quick reference: test-1 has 20 words, test-2 has 24, test-3 has 14, test-4 has 18, test-5 has 28

/// Scripture with punctuation for testing auto-fill behavior in typing mode.
final punctuatedScripture = Scripture(
  id: 'test-punct',
  book: ScriptureBook.bookOfMormon,
  volume: 'Alma',
  reference: 'Alma 32:21',
  name: 'Faith Test',
  keyPhrase: 'Faith is not to have a perfect knowledge',
  fullText:
      'And now, as I said concerning faith—faith is not to have a perfect knowledge of things; therefore if ye have faith ye hope for things which are not seen, which are true.',
);

/// Short scripture with punctuation for simpler tests.
final shortPunctuatedScripture = Scripture(
  id: 'test-short-punct',
  book: ScriptureBook.newTestament,
  volume: 'John',
  reference: 'John 1:1',
  name: 'In the Beginning',
  keyPhrase: 'In the beginning was the Word',
  fullText: 'In the beginning was the Word, and the Word was with God, and the Word was God.',
);
