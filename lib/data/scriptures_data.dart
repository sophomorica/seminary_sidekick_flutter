import '../models/scripture.dart';
import '../models/enums.dart';

// All 95 Doctrinal Mastery scriptures organized by volume

final List<Scripture> allScriptures = [
  // Old Testament (including Pearl of Great Price) - 24 passages
  Scripture(
      id: '1',
      book: ScriptureBook.oldTestament,
      volume: 'Moses',
      reference: 'Moses 1:39',
      name: 'Work and Glory of God',
      keyPhrase:
          'This is my work and my glory—to bring to pass the immortality and eternal life of man.',
      fullText:
          'For behold, this is my work and my glory—to bring to pass the immortality and eternal life of man.'),
  Scripture(
      id: '2',
      book: ScriptureBook.oldTestament,
      volume: 'Moses',
      reference: 'Moses 7:18',
      name: 'Zion',
      keyPhrase:
          'The Lord called his people Zion, because they were of one heart and one mind.',
      fullText:
          'And the Lord called his people Zion, because they were of one heart and one mind, and dwelt in righteousness; and there was no poor among them.'),
  Scripture(
      id: '3',
      book: ScriptureBook.oldTestament,
      volume: 'Abraham',
      reference: 'Abraham 2:9–11',
      name: 'Abrahamic Covenant',
      keyPhrase:
          'The Lord promised Abraham that his seed would “bear this ministry and Priesthood unto all nations.”',
      fullText:
          'And I will make of thee a great nation, and I will bless thee above measure, and make thy name great among all nations, and thou shalt be a blessing unto thy seed after thee, that in their hands they shall bear this ministry and Priesthood unto all nations; And I will bless them through thy name; for as many as receive this Gospel shall be called after thy name, and shall be accounted thy seed, and shall rise up and bless thee, as their father; And I will bless them that bless thee, and curse them that curse thee; and in thee (that is, in thy Priesthood) and in thy seed (that is, thy Priesthood), for I give unto thee a promise that this right shall continue in thee, and in thy seed after thee (that is to say, the literal seed, or the seed of the body) shall all the families of the earth be blessed, even with the blessings of the Gospel, which are the blessings of salvation, even of life eternal.'),
  Scripture(
      id: '4',
      book: ScriptureBook.oldTestament,
      volume: 'Abraham',
      reference: 'Abraham 3:22–23',
      name: 'Pre-Mortal Existence',
      keyPhrase: 'As spirits we “were organized before the world was.”',
      fullText:
          'Now the Lord had shown unto me, Abraham, the intelligences that were organized before the world was; and among all these there were many of the noble and great ones; And God saw these souls that they were good, and he stood in the midst of them, and he said: These I will make my rulers; for he stood among those that were spirits, and he saw that they were good; and he said unto me: Abraham, thou art one of them; thou wast chosen before thou wast born.'),
  Scripture(
      id: '5',
      book: ScriptureBook.oldTestament,
      volume: 'Genesis',
      reference: 'Genesis 1:26–27',
      name: 'Creation of Man',
      keyPhrase: '“God created man in his own image.”',
      fullText:
          'And God said, Let us make man in our image, after our likeness: and let them have dominion over the fish of the sea, and over the fowl of the air, and over the cattle, and over all the earth, and over every creeping thing that creepeth upon the earth. So God created man in his own image, in the image of God created he him; male and female created he them.'),
  Scripture(
      id: '6',
      book: ScriptureBook.oldTestament,
      volume: 'Genesis',
      reference: 'Genesis 2:24',
      name: 'Marriage',
      keyPhrase: '“A man … shall cleave unto his wife: and they shall be one.”',
      fullText:
          'Therefore shall a man leave his father and his mother, and shall cleave unto his wife: and they shall be one flesh.'),
  Scripture(
      id: '7',
      book: ScriptureBook.oldTestament,
      volume: 'Genesis',
      reference: 'Genesis 39:9',
      name: 'Fidelity',
      keyPhrase:
          '“How then can I do this great wickedness, and sin against God?”',
      fullText:
          'There is none greater in this house than I; neither hath he kept back any thing from me but thee, because thou art his wife: how then can I do this great wickedness, and sin against God?'),
  Scripture(
      id: '8',
      book: ScriptureBook.oldTestament,
      volume: 'Exodus',
      reference: 'Exodus 20:3–17',
      name: 'The Ten Commandments',
      keyPhrase: 'The Ten Commandments',
      fullText:
          'Thou shalt have no other gods before me. Thou shalt not make unto thee any graven image, or any likeness of any thing that is in heaven above, or that is in the earth beneath, or that is in the water under the earth: Thou shalt not bow down thyself to them, nor serve them: for I the Lord thy God am a jealous God, visiting the iniquity of the fathers upon the children unto the third and fourth generation of them that hate me; And shewing mercy unto thousands of them that love me, and keep my commandments. Thou shalt not take the name of the Lord thy God in vain; for the Lord will not hold him guiltless that taketh his name in vain. Remember the sabbath day, to keep it holy. Six days shalt thou labour, and do all thy work: But the seventh day is the sabbath of the Lord thy God: in it thou shalt not do any work, thou, nor thy son, nor thy daughter, thy manservant, nor thy maidservant, nor thy cattle, nor thy stranger that is within thy gates: For in six days the Lord made heaven and earth, the sea, and all that in them is, and rested the seventh day: wherefore the Lord blessed the sabbath day, and hallowed it. Honour thy father and thy mother: that thy days may be long upon the land which the Lord thy God giveth thee. Thou shalt not kill. Thou shalt not commit adultery. Thou shalt not steal. Thou shalt not bear false witness against thy neighbour. Thou shalt not covet thy neighbour\'s house, thou shalt not covet thy neighbour\'s wife, nor his manservant, nor his maidservant, nor his ox, nor his ass, nor any thing that is thy neighbour\'s.'),
  Scripture(
      id: '9',
      book: ScriptureBook.oldTestament,
      volume: 'Joshua',
      reference: 'Joshua 24:15',
      name: 'Choose to Serve God',
      keyPhrase: '“Choose you this day whom ye will serve.”',
      fullText:
          'And if it seem evil unto you to serve the Lord, choose you this day whom ye will serve; whether the gods which your fathers served that were on the other side of the flood, or the gods of the Amorites, in whose land ye dwell: but as for me and my house, we will serve the Lord.'),
  Scripture(
      id: '10',
      book: ScriptureBook.oldTestament,
      volume: 'Psalms',
      reference: 'Psalm 24:3–4',
      name: 'Clean Hands and Pure Heart',
      keyPhrase:
          '“Who shall stand in his holy place? He that hath clean hands, and a pure heart.”',
      fullText:
          'Who shall ascend into the hill of the Lord? or who shall stand in his holy place? He that hath clean hands, and a pure heart; who hath not lifted up his soul unto vanity, nor sworn deceitfully.'),
  Scripture(
      id: '11',
      book: ScriptureBook.oldTestament,
      volume: 'Proverbs',
      reference: 'Proverbs 3:5–6',
      name: 'Trust in the Lord',
      keyPhrase:
          '“Trust in the Lord with all thine heart … and he shall direct thy paths.”',
      fullText:
          'Trust in the Lord with all thine heart; and lean not unto thine own understanding. In all thy ways acknowledge him, and he shall direct thy paths.'),
  Scripture(
      id: '12',
      book: ScriptureBook.oldTestament,
      volume: 'Isaiah',
      reference: 'Isaiah 1:18',
      name: 'Sins Made White',
      keyPhrase:
          '“Though your sins be as scarlet, they shall be as white as snow.”',
      fullText:
          'Come now, and let us reason together, saith the Lord: though your sins be as scarlet, they shall be as white as snow; though they be red like crimson, they shall be as wool.'),
  Scripture(
      id: '13',
      book: ScriptureBook.oldTestament,
      volume: 'Isaiah',
      reference: 'Isaiah 5:20',
      name: 'Woe to Those Who Distort Good and Evil',
      keyPhrase: '“Woe unto them that call evil good, and good evil.”',
      fullText:
          'Woe unto them that call evil good, and good evil; that put darkness for light, and light for darkness; that put bitter for sweet, and sweet for bitter!'),
  Scripture(
      id: '14',
      book: ScriptureBook.oldTestament,
      volume: 'Isaiah',
      reference: 'Isaiah 29:13–14',
      name: 'Restoration of the Gospel',
      keyPhrase:
          'The restoration of the gospel is “a marvellous work and a wonder.”',
      fullText:
          'Wherefore the Lord said, Forasmuch as this people draw near me with their mouth, and with their lips do honour me, but have removed their heart far from me, and their fear toward me is taught by the precept of men: Therefore, behold, I will proceed to do a marvellous work among this people, even a marvellous work and a wonder: for the wisdom of their wise men shall perish, and the understanding of their prudent men shall be hid.'),
  Scripture(
      id: '15',
      book: ScriptureBook.oldTestament,
      volume: 'Isaiah',
      reference: 'Isaiah 53:3–5',
      name: 'Christ’s Atonement',
      keyPhrase:
          '“Surely [Jesus Christ] hath borne our griefs, and carried our sorrows.”',
      fullText:
          'He is despised and rejected of men; a man of sorrows, and acquainted with grief: and we hid as it were our faces from him; he was despised, and we esteemed him not. Surely he hath borne our griefs, and carried our sorrows: yet we did esteem him stricken, smitten of God, and afflicted. But he was wounded for our transgressions, he was bruised for our iniquities: the chastisement of our peace was upon him; and with his stripes we are healed.'),
  Scripture(
      id: '16',
      book: ScriptureBook.oldTestament,
      volume: 'Isaiah',
      reference: 'Isaiah 58:6–7',
      name: 'Blessings of a Proper Fast',
      keyPhrase: 'The blessings of a proper fast',
      fullText:
          'Is not this the fast that I have chosen? to loose the bands of wickedness, to undo the heavy burdens, and to let the oppressed go free, and that ye break every yoke? Is it not to deal thy bread to the hungry, and that thou bring the poor that are cast out to thy house? when thou seest the naked, that thou cover him; and that thou hide not thyself from thine own flesh?'),
  Scripture(
      id: '17',
      book: ScriptureBook.oldTestament,
      volume: 'Isaiah',
      reference: 'Isaiah 58:13–14',
      name: 'Sabbath Day',
      keyPhrase:
          '“Turn away … from doing thy pleasure on my holy day; and call the sabbath a delight.”',
      fullText:
          'If thou turn away thy foot from the sabbath, from doing thy pleasure on my holy day; and call the sabbath a delight, the holy of the Lord, honourable; and shalt honour him, not doing thine own ways, nor finding thine own pleasure, nor speaking thine own words: Then shalt thou delight thyself in the Lord; and I will cause thee to ride upon the high places of the earth, and feed thee with the heritage of Jacob thy father: for the mouth of the Lord hath spoken it.'),
  Scripture(
      id: '18',
      book: ScriptureBook.oldTestament,
      volume: 'Jeremiah',
      reference: 'Jeremiah 1:4–5',
      name: 'Foreordination',
      keyPhrase:
          '“Before I formed thee in the belly … I ordained thee a prophet unto the nations.”',
      fullText:
          'Then the word of the Lord came unto me, saying, Before I formed thee in the belly I knew thee; and before thou camest forth out of the womb I sanctified thee, and I ordained thee a prophet unto the nations.'),
  Scripture(
      id: '19',
      book: ScriptureBook.oldTestament,
      volume: 'Ezekiel',
      reference: 'Ezekiel 3:16–17',
      name: 'The Prophet as a Watchman',
      keyPhrase: 'The prophet is “a watchman unto the house of Israel.”',
      fullText:
          'And it came to pass at the end of seven days, that the word of the Lord came unto me, saying, Son of man, I have made thee a watchman unto the house of Israel: therefore hear the word at my mouth, and give them warning from me.'),
  Scripture(
      id: '20',
      book: ScriptureBook.oldTestament,
      volume: 'Ezekiel',
      reference: 'Ezekiel 37:15–17',
      name: 'Bible and Book of Mormon',
      keyPhrase:
          'The Bible and the Book of Mormon “shall become one in thine hand.”',
      fullText:
          'The word of the Lord came again unto me, saying, Moreover, thou son of man, take thee one stick, and write upon it, For Judah, and for the children of Israel his companions: then take another stick, and write upon it, For Joseph, the stick of Ephraim, and for all the house of Israel his companions: And join them one to another into one stick; and they shall become one in thine hand.'),
  Scripture(
      id: '21',
      book: ScriptureBook.oldTestament,
      volume: 'Daniel',
      reference: 'Daniel 2:44–45',
      name: 'God’s Kingdom',
      keyPhrase:
          'God shall “set up a kingdom, which shall never be destroyed.”',
      fullText:
          'And in the days of these kings shall the God of heaven set up a kingdom, which shall never be destroyed: and the kingdom shall not be left to other people, but it shall break in pieces and consume all these kingdoms, and it shall stand for ever. Forasmuch as thou sawest that the stone was cut out of the mountain without hands, and that it brake in pieces the iron, the brass, the clay, the silver, and the gold; the great God hath made known to the king what shall come to pass hereafter: and the dream is certain, and the interpretation thereof sure.'),
  Scripture(
      id: '22',
      book: ScriptureBook.oldTestament,
      volume: 'Amos',
      reference: 'Amos 3:7',
      name: 'God Reveals Secrets to Prophets',
      keyPhrase:
          '“The Lord God … revealeth his secret unto his servants the prophets.”',
      fullText:
          'Surely the Lord God will do nothing, but he revealeth his secret unto his servants the prophets.'),
  Scripture(
      id: '23',
      book: ScriptureBook.oldTestament,
      volume: 'Malachi',
      reference: 'Malachi 3:8–10',
      name: 'Blessings of Tithing',
      keyPhrase: 'The blessings of paying tithing',
      fullText:
          'Will a man rob God? Yet ye have robbed me. But ye say, Wherein have we robbed thee? In tithes and offerings. Ye are cursed with a curse: for ye have robbed me, even this whole nation. Bring ye all the tithes into the storehouse, that there may be meat in mine house, and prove me now herewith, saith the Lord of hosts, if I will not open you the windows of heaven, and pour you out a blessing, that there shall not be room enough to receive it.'),
  Scripture(
      id: '24',
      book: ScriptureBook.oldTestament,
      volume: 'Malachi',
      reference: 'Malachi 4:5–6',
      name: 'Elijah to Turn Hearts',
      keyPhrase:
          'Elijah “shall turn … the heart of the children to their fathers.”',
      fullText:
          'Behold, I will send you Elijah the prophet before the coming of the great and dreadful day of the Lord: And he shall turn the heart of the fathers to the children, and the heart of the children to their fathers, lest I come and smite the earth with a curse.'),

  // New Testament - 24 passages (25–48)
  Scripture(
      id: '25',
      book: ScriptureBook.newTestament,
      volume: 'Matthew',
      reference: 'Matthew 5:14–16',
      name: 'Light Shine',
      keyPhrase: '“Let your light so shine before men.”',
      fullText:
          'Ye are the light of the world. A city that is set on an hill cannot be hid. Neither do men light a candle, and put it under a bushel, but on a candlestick; and it giveth light unto all that are in the house. Let your light so shine before men, that they may see your good works, and glorify your Father which is in heaven.'),
  Scripture(
      id: '26',
      book: ScriptureBook.newTestament,
      volume: 'Matthew',
      reference: 'Matthew 11:28–30',
      name: 'Rest in Christ',
      keyPhrase:
          '“Come unto me, all ye that labour and are heavy laden, and I will give you rest.”',
      fullText:
          'Come unto me, all ye that labour and are heavy laden, and I will give you rest. Take my yoke upon you, and learn of me; for I am meek and lowly in heart: and ye shall find rest unto your souls. For my yoke is easy, and my burden is light.'),
  Scripture(
      id: '27',
      book: ScriptureBook.newTestament,
      volume: 'Matthew',
      reference: 'Matthew 16:15–19',
      name: 'Keys of the Kingdom',
      keyPhrase: 'Jesus said, “I will give unto thee the keys of the kingdom.”',
      fullText:
          'He saith unto them, But whom say ye that I am? And Simon Peter answered and said, Thou art the Christ, the Son of the living God. And Jesus answered and said unto him, Blessed art thou, Simon Bar-jona: for flesh and blood hath not revealed it unto thee, but my Father which is in heaven. And I say also unto thee, That thou art Peter, and upon this rock I will build my church; and the gates of hell shall not prevail against it. And I will give unto thee the keys of the kingdom of heaven: and whatsoever thou shalt bind on earth shall be bound in heaven: and whatsoever thou shalt loose on earth shall be loosed in heaven.'),
  Scripture(
      id: '28',
      book: ScriptureBook.newTestament,
      volume: 'Matthew',
      reference: 'Matthew 22:36–39',
      name: 'Love God and Neighbor',
      keyPhrase:
          '“Thou shalt love the Lord thy God. … Thou shalt love thy neighbour.”',
      fullText:
          'Master, which is the great commandment in the law? Jesus said unto him, Thou shalt love the Lord thy God with all thy heart, and with all thy soul, and with all thy mind. This is the first and great commandment. And the second is like unto it, Thou shalt love thy neighbour as thyself.'),
  Scripture(
      id: '29',
      book: ScriptureBook.newTestament,
      volume: 'Luke',
      reference: 'Luke 2:10–12',
      name: 'Christ’s Birth',
      keyPhrase:
          '“For unto you is born this day in the city of David a Saviour, which is Christ the Lord.”',
      fullText:
          'And the angel said unto them, Fear not: for, behold, I bring you good tidings of great joy, which shall be to all people. For unto you is born this day in the city of David a Saviour, which is Christ the Lord. And this shall be a sign unto you; Ye shall find the babe wrapped in swaddling clothes, lying in a manger.'),
  Scripture(
      id: '30',
      book: ScriptureBook.newTestament,
      volume: 'Luke',
      reference: 'Luke 22:19–20',
      name: 'Sacrament Remembrance',
      keyPhrase:
          'Jesus Christ commanded, partake of the sacrament “in remembrance of me.”',
      fullText:
          'And he took bread, and gave thanks, and brake it, and gave unto them, saying, This is my body which is given for you: this do in remembrance of me. Likewise also the cup after supper, saying, This cup is the new testament in my blood, which is shed for you.'),
  Scripture(
      id: '31',
      book: ScriptureBook.newTestament,
      volume: 'Luke',
      reference: 'Luke 24:36–39',
      name: 'Christ’s Resurrected Body',
      keyPhrase: '“For a spirit hath not flesh and bones, as ye see me have.”',
      fullText:
          'And as they thus spake, Jesus himself stood in the midst of them, and saith unto them, Peace be unto you. But they were terrified and affrighted, and supposed that they had seen a spirit. And he said unto them, Why are ye troubled? and why do thoughts arise in your hearts? Behold my hands and my feet, that it is I myself: handle me, and see; for a spirit hath not flesh and bones, as ye see me have.'),
  Scripture(
      id: '32',
      book: ScriptureBook.newTestament,
      volume: 'John',
      reference: 'John 3:5',
      name: 'Born of Water and Spirit',
      keyPhrase:
          '“Except a man be born of water and of the Spirit, he cannot enter into the kingdom of God.”',
      fullText:
          'Jesus answered, Verily, verily, I say unto thee, Except a man be born of water and of the Spirit, he cannot enter into the kingdom of God.'),
  Scripture(
      id: '33',
      book: ScriptureBook.newTestament,
      volume: 'John',
      reference: 'John 3:16',
      name: 'God’s Love',
      keyPhrase:
          '“For God so loved the world, that he gave his only begotten Son.”',
      fullText:
          'For God so loved the world, that he gave his only begotten Son, that whosoever believeth in him should not perish, but have everlasting life.'),
  Scripture(
      id: '34',
      book: ScriptureBook.newTestament,
      volume: 'John',
      reference: 'John 7:17',
      name: 'Knowing Doctrine',
      keyPhrase:
          '“If any man will do his will, he shall know of the doctrine.”',
      fullText:
          'If any man will do his will, he shall know of the doctrine, whether it be of God, or whether I speak of myself.'),
  Scripture(
      id: '35',
      book: ScriptureBook.newTestament,
      volume: 'John',
      reference: 'John 17:3',
      name: 'Life Eternal',
      keyPhrase:
          '“And this is life eternal, that they might know thee the only true God, and Jesus Christ.”',
      fullText:
          'And this is life eternal, that they might know thee the only true God, and Jesus Christ, whom thou hast sent.'),
  Scripture(
      id: '36',
      book: ScriptureBook.newTestament,
      volume: '1 Corinthians',
      reference: '1 Corinthians 6:19–20',
      name: 'Body as a Temple',
      keyPhrase: '“Your body is the temple of the Holy Ghost.”',
      fullText:
          'What? know ye not that your body is the temple of the Holy Ghost which is in you, which ye have of God, and ye are not your own? For ye are bought with a price: therefore glorify God in your body, and in your spirit, which are God\'s.'),
  Scripture(
      id: '37',
      book: ScriptureBook.newTestament,
      volume: '1 Corinthians',
      reference: '1 Corinthians 11:11',
      name: 'Man and Woman',
      keyPhrase:
          '“Neither is the man without the woman, neither the woman without the man, in the Lord.”',
      fullText:
          'Nevertheless neither is the man without the woman, neither the woman without the man, in the Lord.'),
  Scripture(
      id: '38',
      book: ScriptureBook.newTestament,
      volume: '1 Corinthians',
      reference: '1 Corinthians 15:20–22',
      name: 'Resurrection',
      keyPhrase:
          '“As in Adam all die, even so in Christ shall all be made alive.”',
      fullText:
          'But now is Christ risen from the dead, and become the firstfruits of them that slept. For since by man came death, by man came also the resurrection of the dead. For as in Adam all die, even so in Christ shall all be made alive.'),
  Scripture(
      id: '39',
      book: ScriptureBook.newTestament,
      volume: '1 Corinthians',
      reference: '1 Corinthians 15:40–42',
      name: 'Degrees of Glory',
      keyPhrase: 'In the Resurrection, there are three degrees of glory.',
      fullText:
          'There are also celestial bodies, and bodies terrestrial: but the glory of the celestial is one, and the glory of the terrestrial is another. There is one glory of the sun, and another glory of the moon, and another glory of the stars: for one star differeth from another star in glory. So also is the resurrection of the dead. It is sown in corruption; it is raised in incorruption.'),
  Scripture(
      id: '40',
      book: ScriptureBook.newTestament,
      volume: 'Ephesians',
      reference: 'Ephesians 1:10',
      name: 'Gathering in Christ',
      keyPhrase:
          '“In the dispensation of the fulness of times he might gather together in one all things in Christ.”',
      fullText:
          'That in the dispensation of the fulness of times he might gather together in one all things in Christ, both which are in heaven, and which are on earth; even in him.'),
  Scripture(
      id: '41',
      book: ScriptureBook.newTestament,
      volume: 'Ephesians',
      reference: 'Ephesians 2:19–20',
      name: 'Church Foundation',
      keyPhrase:
          'The Church is “built upon the foundation of the apostles and prophets, Jesus Christ himself being the chief corner stone.”',
      fullText:
          'Now therefore ye are no more strangers and foreigners, but fellowcitizens with the saints, and of the household of God; And are built upon the foundation of the apostles and prophets, Jesus Christ himself being the chief corner stone.'),
  Scripture(
      id: '42',
      book: ScriptureBook.newTestament,
      volume: '2 Thessalonians',
      reference: '2 Thessalonians 2:1–3',
      name: 'Falling Away',
      keyPhrase:
          '“The day of Christ … shall not come, except there come a falling away first.”',
      fullText:
          'Now we beseech you, brethren, by the coming of our Lord Jesus Christ, and by our gathering together unto him, That ye be not soon shaken in mind, or be troubled, neither by spirit, nor by word, nor by letter as from us, as that the day of Christ is at hand. Let no man deceive you by any means: for that day shall not come, except there come a falling away first, and that man of sin be revealed, the son of perdition.'),
  Scripture(
      id: '43',
      book: ScriptureBook.newTestament,
      volume: '2 Timothy',
      reference: '2 Timothy 3:15–17',
      name: 'Scriptures for Salvation',
      keyPhrase:
          '“The holy scriptures … are able to make thee wise unto salvation.”',
      fullText:
          'And that from a child thou hast known the holy scriptures, which are able to make thee wise unto salvation through faith which is in Christ Jesus. All scripture is given by inspiration of God, and is profitable for doctrine, for reproof, for correction, for instruction in righteousness: That the man of God may be perfect, throughly furnished unto all good works.'),
  Scripture(
      id: '44',
      book: ScriptureBook.newTestament,
      volume: 'Hebrews',
      reference: 'Hebrews 12:9',
      name: 'Father of Spirits',
      keyPhrase: 'Heavenly Father is “the Father of spirits.”',
      fullText:
          'Furthermore we have had fathers of our flesh which corrected us, and we gave them reverence: shall we not much rather be in subjection unto the Father of spirits, and live?'),
  Scripture(
      id: '45',
      book: ScriptureBook.newTestament,
      volume: 'James',
      reference: 'James 1:5–6',
      name: 'Ask for Wisdom',
      keyPhrase: '“If any of you lack wisdom, let him ask of God.”',
      fullText:
          'If any of you lack wisdom, let him ask of God, that giveth to all men liberally, and upbraideth not; and it shall be given him. But let him ask in faith, nothing wavering. For he that wavereth is like a wave of the sea driven with the wind and tossed.'),
  Scripture(
      id: '46',
      book: ScriptureBook.newTestament,
      volume: 'James',
      reference: 'James 2:17–18',
      name: 'Faith and Works',
      keyPhrase: '“Faith, if it hath not works, is dead.”',
      fullText:
          'Even so faith, if it hath not works, is dead, being alone. Yea, a man may say, Thou hast faith, and I have works: shew me thy faith without thy works, and I will shew thee my faith by my works.'),
  Scripture(
      id: '47',
      book: ScriptureBook.newTestament,
      volume: '1 Peter',
      reference: '1 Peter 4:6',
      name: 'Gospel Preached to the Dead',
      keyPhrase: '“The gospel [was] preached also to them that are dead.”',
      fullText:
          'For for this cause was the gospel preached also to them that are dead, that they might be judged according to men in the flesh, but live according to God in the spirit.'),
  Scripture(
      id: '48',
      book: ScriptureBook.newTestament,
      volume: 'Revelation',
      reference: 'Revelation 20:12',
      name: 'Judgment by Works',
      keyPhrase: '“And the dead were judged … according to their works.”',
      fullText:
          'And I saw the dead, small and great, stand before God; and the books were opened: and another book was opened, which is the book of life: and the dead were judged out of those things which were written in the books, according to their works.'),

  // Book of Mormon - 24 passages (49–72)
  Scripture(
      id: '49',
      book: ScriptureBook.bookOfMormon,
      volume: '1 Nephi',
      reference: '1 Nephi 3:7',
      name: 'Obedience to Commandments',
      keyPhrase: '“I will go and do the things which the Lord hath commanded.”',
      fullText:
          'And it came to pass that I, Nephi, said unto my father: I will go and do the things which the Lord hath commanded, for I know that the Lord giveth no commandments unto the children of men, save he shall prepare a way for them that they may accomplish the thing which he commandeth them.'),
  Scripture(
      id: '50',
      book: ScriptureBook.bookOfMormon,
      volume: '2 Nephi',
      reference: '2 Nephi 2:25',
      name: 'Purpose of Life',
      keyPhrase:
          '“Adam fell that men might be; and men are, that they might have joy.”',
      fullText:
          'Adam fell that men might be; and men are, that they might have joy.'),
  Scripture(
      id: '51',
      book: ScriptureBook.bookOfMormon,
      volume: '2 Nephi',
      reference: '2 Nephi 2:27',
      name: 'Freedom to Choose',
      keyPhrase:
          '“They are free to choose liberty and eternal life … or … captivity and death.”',
      fullText:
          'Wherefore, men are free according to the flesh; and all things are given them which are expedient unto man. And they are free to choose liberty and eternal life, through the great Mediator of all men, or to choose captivity and death, according to the captivity and power of the devil; for he seeketh that all men might be miserable like unto himself.'),
  Scripture(
      id: '52',
      book: ScriptureBook.bookOfMormon,
      volume: '2 Nephi',
      reference: '2 Nephi 26:33',
      name: 'Equality before God',
      keyPhrase: '“All are alike unto God.”',
      fullText:
          'For none of these iniquities come of the Lord; for he doeth that which is good among the children of men; and he doeth nothing save it be plain unto the children of men; and he inviteth them all to come unto him and partake of his goodness; and he denieth none that come unto him, black and white, bond and free, male and female; and he remembereth the heathen; and all are alike unto God, both Jew and Gentile.'),
  Scripture(
      id: '53',
      book: ScriptureBook.bookOfMormon,
      volume: '2 Nephi',
      reference: '2 Nephi 28:30',
      name: 'Revelation',
      keyPhrase:
          'God “will give unto the children of men line upon line, precept upon precept.”',
      fullText:
          'For behold, thus saith the Lord God: I will give unto the children of men line upon line, precept upon precept, here a little and there a little; and blessed are those who hearken unto my precepts, and lend an ear unto my counsel, for they shall learn wisdom; for unto him that receiveth I will give more; and from them that shall say, We have enough, from them shall be taken away even that which they have.'),
  Scripture(
      id: '54',
      book: ScriptureBook.bookOfMormon,
      volume: '2 Nephi',
      reference: '2 Nephi 32:3',
      name: 'Feasting on the Word',
      keyPhrase:
          '“Feast upon the words of Christ; for behold, the words of Christ will tell you all things what ye should do.”',
      fullText:
          'Angels speak by the power of the Holy Ghost; wherefore, they speak the words of Christ. Wherefore, I said unto you, feast upon the words of Christ; for behold, the words of Christ will tell you all things what ye should do.'),
  Scripture(
      id: '55',
      book: ScriptureBook.bookOfMormon,
      volume: '2 Nephi',
      reference: '2 Nephi 32:8–9',
      name: 'Necessity of Prayer',
      keyPhrase: '“Ye must pray always.”',
      fullText:
          'And now, my beloved brethren, I perceive that ye ponder still in your hearts; and it grieveth me that I must speak concerning this thing. For if ye would hearken unto the Spirit which teacheth a man to pray, ye would know that ye must pray; for the evil spirit teacheth not a man to pray, but teacheth him that he must not pray. But behold, I say unto you that ye must pray always, and not faint; that ye must not perform any thing unto the Lord save in the first place ye shall pray unto the Father in the name of Christ, that he will consecrate thy performance unto thee, that thy performance may be for the welfare of thy soul.'),
  Scripture(
      id: '56',
      book: ScriptureBook.bookOfMormon,
      volume: 'Mosiah',
      reference: 'Mosiah 2:17',
      name: 'Service to Others',
      keyPhrase:
          '“When ye are in the service of your fellow beings ye are only in the service of your God.”',
      fullText:
          'And behold, I tell you these things that ye may learn wisdom; that ye may learn that when ye are in the service of your fellow beings ye are only in the service of your God.'),
  Scripture(
      id: '57',
      book: ScriptureBook.bookOfMormon,
      volume: 'Mosiah',
      reference: 'Mosiah 2:41',
      name: 'Blessings through Obedience',
      keyPhrase:
          '“Those that keep the commandments of God … are blessed in all things.”',
      fullText:
          'And moreover, I would desire that ye should consider on the blessed and happy state of those that keep the commandments of God. For behold, they are blessed in all things, both temporal and spiritual; and if they hold out faithful to the end they are received into heaven, that thereby they may dwell with God in a state of never-ending happiness. O remember, remember that these things are true; for the Lord God hath spoken it.'),
  Scripture(
      id: '58',
      book: ScriptureBook.bookOfMormon,
      volume: 'Mosiah',
      reference: 'Mosiah 3:19',
      name: 'Overcoming the Natural Man',
      keyPhrase:
          '“[Put] off the natural man and [become] a saint through the atonement of Christ the Lord.”',
      fullText:
          'For the natural man is an enemy to God, and has been from the fall of Adam, and will be, forever and ever, unless he yields to the enticings of the Holy Spirit, and putteth off the natural man and becometh a saint through the atonement of Christ the Lord, and becometh as a child, submissive, meek, humble, patient, full of love, willing to submit to all things which the Lord seeth fit to inflict upon him, even as a child doth submit to his father.'),
  Scripture(
      id: '59',
      book: ScriptureBook.bookOfMormon,
      volume: 'Mosiah',
      reference: 'Mosiah 4:9',
      name: 'Belief in God’s Wisdom',
      keyPhrase: '“Believe in God; … believe that he has all wisdom.”',
      fullText:
          'Believe in God; believe that he is, and that he created all things, both in heaven and in earth; believe that he has all wisdom, and all power, both in heaven and in earth; believe that man doth not comprehend all the things which the Lord can comprehend.'),
  Scripture(
      id: '60',
      book: ScriptureBook.bookOfMormon,
      volume: 'Mosiah',
      reference: 'Mosiah 18:8–10',
      name: 'Covenant through Baptism',
      keyPhrase:
          'Be “baptized in the name of the Lord, as a witness … that ye have entered into a covenant with him.”',
      fullText:
          'And it came to pass that he said unto them: Behold, here are the waters of Mormon (for thus were they called) and now, as ye are desirous to come into the fold of God, and to be called his people, and are willing to bear one another\'s burdens, that they may be light; Yea, and are willing to mourn with those that mourn; yea, and comfort those that stand in need of comfort, and to stand as witnesses of God at all times and in all things, and in all places that ye may be in, even until death, that ye may be redeemed of God, and be numbered with those of the first resurrection, that ye may have eternal life— Now I say unto you, if this be the desire of your hearts, what have you against being baptized in the name of the Lord, as a witness before him that ye have entered into a covenant with him, that ye will serve him and keep his commandments, that he may pour out his Spirit more abundantly upon you?'),
  Scripture(
      id: '61',
      book: ScriptureBook.bookOfMormon,
      volume: 'Alma',
      reference: 'Alma 7:11–13',
      name: 'Christ’s Suffering',
      keyPhrase:
          '“And he shall go forth, suffering pains and afflictions and temptations of every kind.”',
      fullText:
          'And he shall go forth, suffering pains and afflictions and temptations of every kind; and this that the word might be fulfilled which saith he will take upon him the pains and the sicknesses of his people. And he will take upon him death, that he may loose the bands of death which bind his people; and he will take upon him their infirmities, that his bowels may be filled with mercy, according to the flesh, that he may know according to the flesh how to succor his people according to their infirmities. Now the Spirit knoweth all things; nevertheless the Son of God suffereth according to the flesh that he might take upon him the sins of his people, that he might blot out their transgressions according to the power of his deliverance; and now behold, this is the testimony which is in me.'),
  Scripture(
      id: '62',
      book: ScriptureBook.bookOfMormon,
      volume: 'Alma',
      reference: 'Alma 34:9–10',
      name: 'The Atonement',
      keyPhrase:
          '“There must be an atonement made, … an infinite and eternal sacrifice.”',
      fullText:
          'For it is expedient that an atonement should be made; for according to the great plan of the Eternal God there must be an atonement made, or else all mankind must unavoidably perish; yea, all are hardened; yea, all are fallen and are lost, and must perish except it be through the atonement which it is expedient should be made. For it is expedient that there should be a great and last sacrifice; yea, not a sacrifice of man, neither of beast, neither of any manner of fowl; for it shall not be a human sacrifice; but it must be an infinite and eternal sacrifice.'),
  Scripture(
      id: '63',
      book: ScriptureBook.bookOfMormon,
      volume: 'Alma',
      reference: 'Alma 39:9',
      name: 'Avoid Lust',
      keyPhrase: '“Go no more after the lusts of your eyes.”',
      fullText:
          'Now my son, I would that ye should repent and forsake your sins, and go no more after the lusts of your eyes, but cross yourself in all these things; for except ye do this ye can in nowise inherit the kingdom of God. Oh, remember, and take it upon you, and cross yourself in these things.'),
  Scripture(
      id: '64',
      book: ScriptureBook.bookOfMormon,
      volume: 'Alma',
      reference: 'Alma 41:10',
      name: 'Consequences of Wickedness',
      keyPhrase: '“Wickedness never was happiness.”',
      fullText:
          'Do not suppose, because it has been spoken concerning restoration, that ye shall be restored from sin to happiness. Behold, I say unto you, wickedness never was happiness.'),
  Scripture(
      id: '65',
      book: ScriptureBook.bookOfMormon,
      volume: 'Helaman',
      reference: 'Helaman 5:12',
      name: 'Solid Foundation',
      keyPhrase:
          '“It is upon the rock of our Redeemer … that ye must build your foundation.”',
      fullText:
          'And now, my sons, remember, remember that it is upon the rock of our Redeemer, who is Christ, the Son of God, that ye must build your foundation; that when the devil shall send forth his mighty winds, yea, his shafts in the whirlwind, yea, when all his hail and his mighty storm shall beat upon you, it shall have no power over you to drag you down to the gulf of misery and endless wo, because of the rock upon which ye are built, which is a sure foundation, a foundation whereon if men build they cannot fall.'),
  Scripture(
      id: '66',
      book: ScriptureBook.bookOfMormon,
      volume: '3 Nephi',
      reference: '3 Nephi 11:10–11',
      name: 'Christ’s Submission',
      keyPhrase:
          '“I have suffered the will of the Father in all things from the beginning.”',
      fullText:
          'Behold, I am Jesus Christ, whom the prophets testified shall come into the world. And behold, I am the light and the life of the world; and I have drunk out of that bitter cup which the Father hath given me, and have glorified the Father in taking upon me the sins of the world, in the which I have suffered the will of the Father in all things from the beginning.'),
  Scripture(
      id: '67',
      book: ScriptureBook.bookOfMormon,
      volume: '3 Nephi',
      reference: '3 Nephi 12:48',
      name: 'Striving for Perfection',
      keyPhrase:
          '“Be perfect even as I, or your Father who is in heaven is perfect.”',
      fullText:
          'Therefore I would that ye should be perfect even as I, or your Father who is in heaven is perfect.'),
  Scripture(
      id: '68',
      book: ScriptureBook.bookOfMormon,
      volume: '3 Nephi',
      reference: '3 Nephi 27:20',
      name: 'Coming Unto Christ',
      keyPhrase:
          '“Come unto me and be baptized … that ye may be sanctified by the reception of the Holy Ghost.”',
      fullText:
          'Now this is the commandment: Repent, all ye ends of the earth, and come unto me and be baptized in my name, that ye may be sanctified by the reception of the Holy Ghost, that ye may stand spotless before me at the last day.'),
  Scripture(
      id: '69',
      book: ScriptureBook.bookOfMormon,
      volume: 'Ether',
      reference: 'Ether 12:6',
      name: 'Trial of Faith',
      keyPhrase: '“Ye receive no witness until after the trial of your faith.”',
      fullText:
          'And now, I, Moroni, would speak somewhat concerning these things; I would show unto the world that faith is things which are hoped for and not seen; wherefore, dispute not because ye see not, for ye receive no witness until after the trial of your faith.'),
  Scripture(
      id: '70',
      book: ScriptureBook.bookOfMormon,
      volume: 'Ether',
      reference: 'Ether 12:27',
      name: 'Strength in Weakness',
      keyPhrase:
          '“If men come unto me … then will I make weak things become strong unto them.”',
      fullText:
          'And if men come unto me I will show unto them their weakness. I give unto men weakness that they may be humble; and my grace is sufficient for all men that humble themselves before me; for if they humble themselves before me, and have faith in me, then will I make weak things become strong unto them.'),
  Scripture(
      id: '71',
      book: ScriptureBook.bookOfMormon,
      volume: 'Moroni',
      reference: 'Moroni 7:45–48',
      name: 'Charity',
      keyPhrase: '“Charity is the pure love of Christ.”',
      fullText:
          'And charity suffereth long, and is kind, and envieth not, and is not puffed up, seeketh not her own, is not easily provoked, thinketh no evil, and rejoiceth not in iniquity but rejoiceth in the truth, beareth all things, believeth all things, hopeth all things, endureth all things. Wherefore, my beloved brethren, if ye have not charity, ye are nothing, for charity never faileth. Wherefore, cleave unto charity, which is the greatest of all, for all things must fail— But charity is the pure love of Christ, and it endureth forever; and whoso is found possessed of it at the last day, it shall be well with him. Wherefore, my beloved brethren, pray unto the Father with all the energy of heart, that ye may be filled with this love, which he hath bestowed upon all who are true followers of his Son, Jesus Christ; that ye may become the sons of God; that when he shall appear we shall be like him, for we shall see him as he is; that we may have this hope; that we may be purified even as he is pure. Amen.'),
  Scripture(
      id: '72',
      book: ScriptureBook.bookOfMormon,
      volume: 'Moroni',
      reference: 'Moroni 10:4–5',
      name: 'Seeking Truth Through Prayer',
      keyPhrase:
          'Ask with a sincere heart, with real intent, having faith in Christ … [and] by the power of the Holy Ghost ye may know the truth of all things.',
      fullText:
          'And when ye shall receive these things, I would exhort you that ye would ask God, the Eternal Father, in the name of Christ, if these things are not true; and if ye shall ask with a sincere heart, with real intent, having faith in Christ, he will manifest the truth of it unto you, by the power of the Holy Ghost. And by the power of the Holy Ghost ye may know the truth of all things.'),

  // Doctrine and Covenants (including Joseph Smith—History) - 28 passages (73–100)
  // Note: The official list has 28 here to total 100 (24 OT + 24 NT + 24 BoM + 28 D&C = 100)
  Scripture(
      id: '73',
      book: ScriptureBook.doctrineAndCovenants,
      volume: 'Joseph Smith—History',
      reference: 'Joseph Smith—History 1:17',
      name: 'The First Vision',
      keyPhrase:
          'Joseph Smith “saw two Personages, whose brightness and glory defy all description.”',
      fullText:
          'It no sooner appeared than I found myself delivered from the enemy which held me bound. When the light rested upon me I saw two Personages, whose brightness and glory defy all description, standing above me in the air. One of them spake unto me, calling me by name and said, pointing to the other—This is My Beloved Son. Hear Him!'),
  Scripture(
      id: '74',
      book: ScriptureBook.doctrineAndCovenants,
      volume: 'D&C',
      reference: 'D&C 1:30',
      name: 'True and Living Church',
      keyPhrase: '“The only true and living church.”',
      fullText:
          'And also those to whom these commandments were given, might have power to lay the foundation of this church, and to bring it forth out of obscurity and out of darkness, the only true and living church upon the face of the whole earth, with which I, the Lord, am well pleased, speaking unto the church collectively and not individually.'),
  Scripture(
      id: '75',
      book: ScriptureBook.doctrineAndCovenants,
      volume: 'D&C',
      reference: 'D&C 1:37–38',
      name: 'Voice of the Lord',
      keyPhrase:
          '“Whether by mine own voice or by the voice of my servants, it is the same.”',
      fullText:
          'Search these commandments, for they are true and faithful, and the prophecies and promises which are in them shall all be fulfilled. What I the Lord have spoken, I have spoken, and I excuse not myself; and though the heavens and the earth pass away, my word shall not pass away, but shall all be fulfilled, whether by mine own voice or by the voice of my servants, it is the same.'),
  Scripture(
      id: '76',
      book: ScriptureBook.doctrineAndCovenants,
      volume: 'D&C',
      reference: 'D&C 6:36',
      name: 'Trust in Christ',
      keyPhrase: '“Look unto me in every thought; doubt not, fear not.”',
      fullText: 'Look unto me in every thought; doubt not, fear not.'),
  Scripture(
      id: '77',
      book: ScriptureBook.doctrineAndCovenants,
      volume: 'D&C',
      reference: 'D&C 8:2–3',
      name: 'Revelation through the Holy Ghost',
      keyPhrase:
          '“I will tell you in your mind and in your heart, by the Holy Ghost.”',
      fullText:
          'Yea, behold, I will tell you in your mind and in your heart, by the Holy Ghost, which shall come upon you and which shall dwell in your heart. Now, behold, this is the spirit of revelation; behold, this is the spirit by which Moses brought the children of Israel through the Red Sea on dry ground.'),
  Scripture(
      id: '78',
      book: ScriptureBook.doctrineAndCovenants,
      volume: 'D&C',
      reference: 'D&C 13',
      name: 'Aaronic Priesthood',
      keyPhrase:
          'The Aaronic Priesthood “holds the keys of the ministering of angels, and of the gospel of repentance, and of baptism.”',
      fullText:
          'Upon you my fellow servants, in the name of Messiah I confer the Priesthood of Aaron, which holds the keys of the ministering of angels, and of the gospel of repentance, and of baptism by immersion for the remission of sins; and this shall never be taken again from the earth, until the sons of Levi do offer again an offering unto the Lord in righteousness.'),
  Scripture(
      id: '79',
      book: ScriptureBook.doctrineAndCovenants,
      volume: 'D&C',
      reference: 'D&C 18:10',
      name: 'Worth of Souls',
      keyPhrase: '“The worth of souls is great in the sight of God.”',
      fullText: 'Remember the worth of souls is great in the sight of God.'),
  Scripture(
      id: '80',
      book: ScriptureBook.doctrineAndCovenants,
      volume: 'D&C',
      reference: 'D&C 18:15–16',
      name: 'Joy in Bringing Souls',
      keyPhrase:
          '“How great shall be your joy if you should bring many souls unto me!”',
      fullText:
          'And if it so be that you should labor all your days in crying repentance unto this people, and bring, save it be one soul unto me, how great shall be your joy with him in the kingdom of my Father! And now, if your joy will be great with one soul that you have brought unto me into the kingdom of my Father, how great will be your joy if you should bring many souls unto me!'),
  Scripture(
      id: '81',
      book: ScriptureBook.doctrineAndCovenants,
      volume: 'D&C',
      reference: 'D&C 19:16–19',
      name: 'Christ’s Atonement',
      keyPhrase: '“I, God, have suffered these things for all.”',
      fullText:
          'For behold, I, God, have suffered these things for all, that they might not suffer if they would repent; But if they would not repent they must suffer even as I; Which suffering caused myself, even God, the greatest of all, to tremble because of pain, and to bleed at every pore, and to suffer both body and spirit—and would that I might not drink the bitter cup, and shrink— Nevertheless, glory be to the Father, and I partook and finished my preparations unto the children of men.'),
  Scripture(
      id: '82',
      book: ScriptureBook.doctrineAndCovenants,
      volume: 'D&C',
      reference: 'D&C 21:4–6',
      name: 'Receiving the Prophet’s Words',
      keyPhrase:
          '“Thou shalt give heed unto all his words and commandments … as if from mine own mouth.”',
      fullText:
          'Wherefore, meaning the church, thou shalt give heed unto all his words and commandments which he shall give unto you as he receiveth them, walking in all holiness before me; For his word ye shall receive, as if from mine own mouth, in all patience and faith. For by doing these things the gates of hell shall not prevail against you; yea, and the Lord God will disperse the powers of darkness from before you, and cause the heavens to shake for your good, and his name\'s glory.'),
  Scripture(
      id: '83',
      book: ScriptureBook.doctrineAndCovenants,
      volume: 'D&C',
      reference: 'D&C 29:10–11',
      name: 'Second Coming',
      keyPhrase:
          'Christ “will reveal myself from heaven with power and great glory … and dwell in righteousness with men on earth a thousand years.”',
      fullText:
          'For the hour is nigh and the day soon at hand when the earth is ripe; and all the proud and they that do wickedly shall be as stubble; and I will burn them up, saith the Lord of Hosts, that wickedness shall not be upon the earth; For I will reveal myself from heaven with power and great glory, with all the hosts thereof, and dwell in righteousness with men on earth a thousand years, and the wicked shall not stand.'),
  Scripture(
      id: '84',
      book: ScriptureBook.doctrineAndCovenants,
      volume: 'D&C',
      reference: 'D&C 49:15',
      name: 'Marriage Ordained',
      keyPhrase: '“Marriage is ordained of God.”',
      fullText:
          'And again, verily I say unto you, that whoso forbiddeth to marry is not ordained of God, for marriage is ordained of God unto man.'),
  Scripture(
      id: '85',
      book: ScriptureBook.doctrineAndCovenants,
      volume: 'D&C',
      reference: 'D&C 58:42–43',
      name: 'Repentance and Forgiveness',
      keyPhrase: '“He who has repented of his sins, the same is forgiven.”',
      fullText:
          'Behold, he who has repented of his sins, the same is forgiven, and I, the Lord, remember them no more. By this ye may know if a man repenteth of his sins—behold, he will confess them and forsake them.'),
  Scripture(
      id: '86',
      book: ScriptureBook.doctrineAndCovenants,
      volume: 'D&C',
      reference: 'D&C 64:9–11',
      name: 'Requirement to Forgive',
      keyPhrase:
          '“I, the Lord, will forgive whom I will forgive, but of you it is required to forgive all men.”',
      fullText:
          'Wherefore, I say unto you, that ye ought to forgive one another; for he that forgiveth not his brother his trespasses standeth condemned before the Lord; for there remaineth in him the greater sin. I, the Lord, will forgive whom I will forgive, but of you it is required to forgive all men. And ye ought to say in your hearts—let God judge between me and thee, and reward thee according to thy deeds.'),
  Scripture(
      id: '87',
      book: ScriptureBook.doctrineAndCovenants,
      volume: 'D&C',
      reference: 'D&C 76:22–24',
      name: 'Creator and Savior',
      keyPhrase: '“By [Jesus Christ] the worlds are and were created.”',
      fullText:
          'And now, after the many testimonies which have been given of him, this is the testimony, last of all, which we give of him: That he lives! For we saw him, even on the right hand of God; and we heard the voice bearing record that he is the Only Begotten of the Father— That by him, and through him, and of him, the worlds are and were created, and the inhabitants thereof are begotten sons and daughters unto God.'),
  Scripture(
      id: '88',
      book: ScriptureBook.doctrineAndCovenants,
      volume: 'D&C',
      reference: 'D&C 82:10',
      name: 'Obedience Binds the Lord',
      keyPhrase: '“I, the Lord, am bound when ye do what I say.”',
      fullText:
          'I, the Lord, am bound when ye do what I say; but when ye do not what I say, ye have no promise.'),
  Scripture(
      id: '89',
      book: ScriptureBook.doctrineAndCovenants,
      volume: 'D&C',
      reference: 'D&C 84:20–22',
      name: 'Power of Godliness',
      keyPhrase:
          '“In the ordinances thereof, the power of godliness is manifest.”',
      fullText:
          'Therefore, in the ordinances thereof, the power of godliness is manifest. And without the ordinances thereof, and the authority of the priesthood, the power of godliness is not manifest unto men in the flesh; For without this no man can see the face of God, even the Father, and live.'),
  Scripture(
      id: '90',
      book: ScriptureBook.doctrineAndCovenants,
      volume: 'D&C',
      reference: 'D&C 88:118',
      name: 'Seek Learning',
      keyPhrase: '“Seek learning, even by study and also by faith.”',
      fullText:
          'And as all have not faith, seek ye diligently and teach one another words of wisdom; yea, seek ye out of the best books words of wisdom; seek learning, even by study and also by faith.'),
  Scripture(
      id: '91',
      book: ScriptureBook.doctrineAndCovenants,
      volume: 'D&C',
      reference: 'D&C 89:18–21',
      name: 'Word of Wisdom',
      keyPhrase: 'The blessings of the Word of Wisdom',
      fullText:
          'And all saints who remember to keep and do these sayings, walking in obedience to the commandments, shall receive health in their navel and marrow to their bones; And shall find wisdom and great treasures of knowledge, even hidden treasures; And shall run and not be weary, and shall walk and not faint. And I, the Lord, give unto them a promise, that the destroying angel shall pass by them, as the children of Israel, and not slay them. Amen.'),
  Scripture(
      id: '92',
      book: ScriptureBook.doctrineAndCovenants,
      volume: 'D&C',
      reference: 'D&C 107:18–20',
      name: 'Melchizedek Priesthood',
      keyPhrase:
          'The Melchizedek Priesthood “holds the key of the mysteries of the kingdom, even the key of the knowledge of God.”',
      fullText:
          'The power and authority of the higher, or Melchizedek Priesthood, is to hold the keys of all the spiritual blessings of the church— To have the privilege of receiving the mysteries of the kingdom of heaven, to have the heavens opened unto them, to commune with the general assembly and church of the Firstborn, and to enjoy the communion and presence of God the Father, and Jesus the mediator of the new covenant. The Melchizedek Priesthood holds the right of presidency, and has power and authority over all the offices in the church in all ages of the world, to administer in spiritual things.'),
  Scripture(
      id: '93',
      book: ScriptureBook.doctrineAndCovenants,
      volume: 'D&C',
      reference: 'D&C 121:36, 41–42',
      name: 'Rights of the Priesthood',
      keyPhrase:
          '“The rights of the priesthood are inseparably connected with the powers of heaven, and … the powers of heaven cannot be controlled nor handled only on the principles of righteousness.”',
      fullText:
          'That the rights of the priesthood are inseparably connected with the powers of heaven, and that the powers of heaven cannot be controlled nor handled only upon the principles of righteousness. No power or influence can or ought to be maintained by virtue of the priesthood, only by persuasion, by long-suffering, by gentleness and meekness, and by love unfeigned; By kindness, and pure knowledge, which shall greatly enlarge the soul without hypocrisy, and without guile.'),
  Scripture(
      id: '94',
      book: ScriptureBook.doctrineAndCovenants,
      volume: 'D&C',
      reference: 'D&C 130:22–23',
      name: 'Nature of God',
      keyPhrase:
          '“The Father has a body of flesh and bones as tangible as man’s; the Son also; but the Holy Ghost … is a personage of Spirit.”',
      fullText:
          'The Father has a body of flesh and bones as tangible as man\'s; the Son also; but the Holy Ghost has not a body of flesh and bones, but is a personage of Spirit. Were it not so, the Holy Ghost could not dwell in us. A man may receive the Holy Ghost, and it may descend upon him and not tarry with him.'),
  Scripture(
      id: '95',
      book: ScriptureBook.doctrineAndCovenants,
      volume: 'D&C',
      reference: 'D&C 131:1–4',
      name: 'Eternal Marriage',
      keyPhrase:
          'In the celestial glory there are three heavens or degrees; … [and] the new and everlasting covenant of marriage.',
      fullText:
          'In the celestial glory there are three heavens or degrees; And in order to obtain the highest, a man must enter into this order of the priesthood [meaning the new and everlasting covenant of marriage]; And if he does not, he cannot obtain it. He may enter into the other, but that is the end of his kingdom; he cannot have an increase.'),
  Scripture(
      id: '96',
      book: ScriptureBook.doctrineAndCovenants,
      volume: 'D&C',
      reference: 'D&C 135:3',
      name: 'Joseph Smith and Book of Mormon',
      keyPhrase:
          '“Joseph Smith … has done more, save it be Jesus only, for the salvation of men in this world, than any other man that ever lived in it.”',
      fullText:
          'Joseph Smith, the Prophet and Seer of the Lord, has done more, save Jesus only, for the salvation of men in this world, than any other man that ever lived in it. In the short space of twenty years, he has brought forth the Book of Mormon, which he translated by the gift and power of God, and has been the means of publishing it on two continents; has sent the fulness of the everlasting gospel, which it contained, to the four quarters of the earth; has brought forth the revelations and commandments which compose this book of Doctrine and Covenants, and many other wise documents and instructions for the benefit of the children of men; gathered many thousands of the Latter-day Saints, founded a great city, and left a fame and name that cannot be slain. He lived great, and he died great in the eyes of God and his people; and like most of the Lord\'s anointed in ancient times, has sealed his mission and his works with his own blood; and so has his brother Hyrum. In life they were not divided, and in death they were not separated!'), // Missing Doctrine and Covenants passages (IDs 97–100 from official 2023 Core Document)
  Scripture(
    id: '97',
    book: ScriptureBook.doctrineAndCovenants,
    volume: 'D&C',
    reference: 'Doctrine and Covenants 88:81',
    name: 'Go Ye Into All the World',
    keyPhrase:
        '“I give unto you a commandment, that ye shall teach them unto all men.”',
    fullText:
        'Behold, I say unto you, that I have decreed in my heart and in my will that these things shall be taught unto the children of men, that they may know that I am the Lord their God, and that they may be taught to observe all things whatsoever I have commanded them. And I give unto you a commandment, that ye shall teach them unto all men; for they shall be taught unto all men, even unto the ends of the earth.',
  ),
  Scripture(
    id: '98',
    book: ScriptureBook.doctrineAndCovenants,
    volume: 'D&C',
    reference: 'Doctrine and Covenants 93:1',
    name: 'Truth and Light',
    keyPhrase:
        '“Every soul who forsaketh his sins and cometh unto me … shall see my face and know that I am.”',
    fullText:
        'Verily, thus saith the Lord: It shall come to pass that every soul who forsaketh his sins and cometh unto me, and calleth on my name, and obeyeth my voice, and keepeth my commandments, shall see my face and know that I am;',
  ),
  Scripture(
    id: '99',
    book: ScriptureBook.doctrineAndCovenants,
    volume: 'D&C',
    reference: 'Doctrine and Covenants 130:20–21',
    name: 'Obedience and Blessings',
    keyPhrase:
        '“There is a law, irrevocably decreed in heaven … upon which all blessings are predicated.”',
    fullText:
        'There is a law, irrevocably decreed in heaven upon which all blessings are predicated— And when we obtain any blessing from God, it is by obedience to that law upon which it is predicated.',
  ),
  Scripture(
    id: '100',
    book: ScriptureBook.doctrineAndCovenants,
    volume: 'D&C',
    reference: 'Doctrine and Covenants 138:11–12, 32–34',
    name: 'Salvation for the Dead',
    keyPhrase: 'The gospel was preached to the spirits in prison.',
    fullText:
        'As I searched the scriptures, I came to the vision of the redemption of the dead; And I saw the hosts of the dead, both small and great. ... Thus was it made known that our Redeemer spent his time in the world of spirits instructing the faithful spirits who had departed mortality in the way of salvation, teaching them the plan of redemption which had been prepared from the foundation of the world; that through his atonement the great plan of salvation might be accomplished; that they might receive the fulness of joy in the mansions of his Father.',
  ),

];
