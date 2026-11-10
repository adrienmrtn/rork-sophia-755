#!/usr/bin/env python3
"""Source des questions de duel (bêta, anglais) : 137 questions sur 8 niveaux cachés.

Les 80 premières : par niveau, 4 QCM, 2 vrai/faux, 2 portraits (« qui est-ce ? », image
Wikimedia Commons du domaine public, copiée sur Supabase Storage) et 2 curseurs (le plus
proche marque). Puis un complément par matière (art, littérature, mythologie, comprendre le
monde), pour que chaque matière ait de quoi remplir une manche à tous les niveaux. Les
nouvelles questions s'ajoutent à la fin : l'identifiant d'une question suit son rang dans
son niveau, il ne doit pas changer.
La première option d'un QCM ou d'un portrait est la bonne ; scripts/build_duels_seed.py
mélange les options (ordre stable d'une exécution à l'autre) et écrit
content/duels/questions_en.json puis le SQL d'amorçage.

    M(niveau, matière, question, [bonne, fausse, fausse, fausse])
    TF(niveau, matière, affirmation, vrai_ou_faux)
    P(niveau, fichier_portrait, [bonne, fausse, fausse, fausse])
    S(niveau, matière, question, min, max, bonne_valeur, unité, pas=1)
"""

QUESTIONS = []


def M(level, subject, question, options):
    QUESTIONS.append({"level": level, "kind": "mcq", "subject": subject, "question": question, "options": options})


def TF(level, subject, statement, answer):
    QUESTIONS.append({"level": level, "kind": "true_false", "subject": subject, "question": statement, "answer": answer})


# La matière d'un portrait est celle de la personne : une manche « Sciences » peut montrer Curie.
PORTRAIT_SUBJECTS = {
    "albert_einstein": "science", "marie_curie": "science", "charles_darwin": "science",
    "galileo_galilei": "science", "isaac_newton": "science", "ada_lovelace": "science",
    "william_shakespeare": "literature", "virginia_woolf": "literature", "voltaire": "literature",
    "wolfgang_amadeus_mozart": "art", "ludwig_van_beethoven": "art",
    "rene_descartes": "world", "erasmus": "world",
}


def P(level, portrait, options):
    QUESTIONS.append({"level": level, "kind": "portrait", "subject": PORTRAIT_SUBJECTS.get(portrait, "history"),
                      "question": "Who is this?", "portrait": portrait, "options": options})


def S(level, subject, question, lo, hi, value, unit, step=1):
    QUESTIONS.append({"level": level, "kind": "slider", "subject": subject, "question": question,
                      "min": lo, "max": hi, "value": value, "unit": unit, "step": step})


# ---------------------------------------------------------------- niveau 1
M(1, "science", "Which planet is known as the Red Planet?", ["Mars", "Venus", "Jupiter", "Mercury"])
M(1, "art", "Who painted the Mona Lisa?", ["Leonardo da Vinci", "Michelangelo", "Raphael", "Sandro Botticelli"])
M(1, "mythology", "In Greek mythology, who is the king of the gods?", ["Zeus", "Poseidon", "Hades", "Apollo"])
M(1, "history", "In which country are the pyramids of Giza?", ["Egypt", "Mexico", "Greece", "Iraq"])
TF(1, "history", "The Titanic sank on its very first voyage.", True)
TF(1, "science", "Sharks are mammals.", False)
P(1, "albert_einstein", ["Albert Einstein", "Sigmund Freud", "Thomas Edison", "Mark Twain"])
P(1, "napoleon", ["Napoleon Bonaparte", "Louis XIV", "George Washington", "The Duke of Wellington"])
S(1, "history", "In what year did Christopher Columbus first reach the Americas?", 1400, 1600, 1492, "year")
S(1, "science", "In what year did humans first walk on the Moon?", 1940, 2000, 1969, "year")

# ---------------------------------------------------------------- niveau 2
M(2, "literature", "Who wrote \"Pride and Prejudice\"?", ["Jane Austen", "Charlotte Brontë", "Mary Shelley", "George Eliot"])
M(2, "history", "Which ancient city was buried by the eruption of Mount Vesuvius in AD 79?", ["Pompeii", "Athens", "Carthage", "Troy"])
M(2, "science", "What is the chemical symbol for gold?", ["Au", "Ag", "Go", "Gd"])
M(2, "art", "Who painted \"The Starry Night\"?", ["Vincent van Gogh", "Claude Monet", "Pablo Picasso", "Paul Cézanne"])
TF(2, "art", "Leonardo da Vinci painted the ceiling of the Sistine Chapel.", False)
TF(2, "history", "The French Revolution began in 1789.", True)
P(2, "william_shakespeare", ["William Shakespeare", "Christopher Marlowe", "Miguel de Cervantes", "Sir Walter Raleigh"])
P(2, "abraham_lincoln", ["Abraham Lincoln", "Ulysses S. Grant", "Charles Dickens", "Karl Marx"])
S(2, "history", "In what year did the Berlin Wall fall?", 1950, 2000, 1989, "year")
S(2, "world", "What percentage of the Earth's surface is covered by water?", 0, 100, 71, "%")

# ---------------------------------------------------------------- niveau 3
M(3, "mythology", "In Greek mythology, who flew too close to the Sun on wings of wax?", ["Icarus", "Daedalus", "Perseus", "Orpheus"])
M(3, "history", "Who was the first emperor of Rome?", ["Augustus", "Julius Caesar", "Nero", "Constantine"])
M(3, "science", "Which scientist proposed the theory of evolution by natural selection?", ["Charles Darwin", "Gregor Mendel", "Louis Pasteur", "Jean-Baptiste Lamarck"])
M(3, "literature", "Who wrote the novel \"1984\"?", ["George Orwell", "Aldous Huxley", "Ray Bradbury", "H. G. Wells"])
TF(3, "art", "The Renaissance began in Italy.", True)
TF(3, "science", "Sound travels faster than light.", False)
P(3, "marie_curie", ["Marie Curie", "Florence Nightingale", "Rosalind Franklin", "Emmeline Pankhurst"])
P(3, "wolfgang_amadeus_mozart", ["Wolfgang Amadeus Mozart", "Johann Sebastian Bach", "Joseph Haydn", "Antonio Vivaldi"])
S(3, "history", "In what year did the First World War begin?", 1850, 1950, 1914, "year")
S(3, "science", "How many bones are there in the adult human body?", 100, 400, 206, "bones")

# ---------------------------------------------------------------- niveau 4
M(4, "art", "Which artist painted \"Guernica\"?", ["Pablo Picasso", "Salvador Dalí", "Joan Miró", "Henri Matisse"])
M(4, "world", "Which philosopher was the tutor of Alexander the Great?", ["Aristotle", "Plato", "Socrates", "Epicurus"])
M(4, "science", "Which particle carries a negative electric charge?", ["Electron", "Proton", "Neutron", "Photon"])
M(4, "mythology", "In Norse mythology, what is the name of Thor's hammer?", ["Mjölnir", "Gungnir", "Excalibur", "Gram"])
TF(4, "history", "The Great Fire of London took place in 1666.", True)
TF(4, "literature", "\"Don Quixote\" was written by Dante.", False)
P(4, "charles_darwin", ["Charles Darwin", "John Stuart Mill", "Thomas Henry Huxley", "Charles Dickens"])
P(4, "queen_victoria", ["Queen Victoria", "Catherine the Great", "Empress Elisabeth of Austria", "Queen Elizabeth I"])
S(4, "history", "Around what year was the Gutenberg Bible printed?", 1300, 1600, 1455, "year")
S(4, "science", "How many chemical elements are in the periodic table today?", 50, 200, 118, "elements")

# ---------------------------------------------------------------- niveau 5
M(5, "literature", "Who wrote \"The Divine Comedy\"?", ["Dante Alighieri", "Petrarch", "Giovanni Boccaccio", "Virgil"])
M(5, "history", "Which treaty, signed in 1919, ended the First World War with Germany?", ["Treaty of Versailles", "Treaty of Vienna", "Treaty of Tordesillas", "Treaty of Westphalia"])
M(5, "art", "Which Dutch painter created \"Girl with a Pearl Earring\"?", ["Johannes Vermeer", "Rembrandt", "Frans Hals", "Jan van Eyck"])
M(5, "science", "Which scientist discovered penicillin in 1928?", ["Alexander Fleming", "Louis Pasteur", "Robert Koch", "Edward Jenner"])
TF(5, "mythology", "In Greek mythology, Medusa was one of the three Gorgons.", True)
TF(5, "history", "The Hundred Years' War lasted exactly 100 years.", False)
P(5, "ludwig_van_beethoven", ["Ludwig van Beethoven", "Franz Schubert", "Richard Wagner", "Johann Wolfgang von Goethe"])
P(5, "galileo_galilei", ["Galileo Galilei", "Johannes Kepler", "Nicolaus Copernicus", "Leonardo da Vinci"])
S(5, "history", "In what year did Constantinople fall to the Ottomans?", 1200, 1700, 1453, "year")
S(5, "science", "About how many minutes does sunlight take to reach the Earth?", 1, 60, 8, "min")

# ---------------------------------------------------------------- niveau 6
M(6, "world", "Which economist wrote \"The Wealth of Nations\" (1776)?", ["Adam Smith", "Karl Marx", "David Ricardo", "John Maynard Keynes"])
M(6, "art", "Which sculptor created \"The Thinker\"?", ["Auguste Rodin", "Michelangelo", "Donatello", "Gian Lorenzo Bernini"])
M(6, "mythology", "In the Epic of Gilgamesh, of which city is Gilgamesh the king?", ["Uruk", "Babylon", "Ur", "Nineveh"])
M(6, "science", "Which astronomer formulated the three laws of planetary motion?", ["Johannes Kepler", "Tycho Brahe", "Nicolaus Copernicus", "Galileo Galilei"])
TF(6, "history", "The Byzantine Empire was the eastern continuation of the Roman Empire.", True)
TF(6, "literature", "Franz Kafka wrote \"The Metamorphosis\" in French.", False)
P(6, "isaac_newton", ["Isaac Newton", "Gottfried Wilhelm Leibniz", "John Locke", "Christiaan Huygens"])
P(6, "virginia_woolf", ["Virginia Woolf", "Emily Dickinson", "Sylvia Plath", "Katherine Mansfield"])
S(6, "history", "In what year was Magna Carta sealed?", 1000, 1500, 1215, "year")
S(6, "science", "What percentage of the Earth's atmosphere is nitrogen?", 0, 100, 78, "%")

# ---------------------------------------------------------------- niveau 7
M(7, "world", "Which philosopher wrote the \"Critique of Pure Reason\"?", ["Immanuel Kant", "Georg Wilhelm Friedrich Hegel", "Arthur Schopenhauer", "Gottfried Wilhelm Leibniz"])
M(7, "history", "Which settlement of 1648 ended the Thirty Years' War?", ["Peace of Westphalia", "Peace of Augsburg", "Treaty of Utrecht", "Congress of Vienna"])
M(7, "art", "Who painted \"The Garden of Earthly Delights\"?", ["Hieronymus Bosch", "Pieter Bruegel the Elder", "Jan van Eyck", "Albrecht Dürer"])
M(7, "mythology", "In Hindu tradition, which god is known as the preserver?", ["Vishnu", "Shiva", "Brahma", "Indra"])
TF(7, "literature", "James Joyce's \"Ulysses\" takes place over a single day in Dublin.", True)
TF(7, "science", "Marie Curie won Nobel Prizes in both Physics and Medicine.", False)
P(7, "voltaire", ["Voltaire", "Jean-Jacques Rousseau", "Denis Diderot", "Montesquieu"])
P(7, "ada_lovelace", ["Ada Lovelace", "Mary Shelley", "Jane Austen", "Charlotte Brontë"])
S(7, "history", "In what year did the Western Roman Empire fall?", 200, 700, 476, "year")
S(7, "science", "In what year did Dmitri Mendeleev publish his periodic table?", 1750, 1950, 1869, "year")

# ---------------------------------------------------------------- niveau 8
M(8, "history", "Which Byzantine emperor had the Hagia Sophia built, completed in 537?", ["Justinian I", "Constantine I", "Heraclius", "Basil II"])
M(8, "literature", "Who wrote \"The Tale of Genji\", often called the world's first novel?", ["Murasaki Shikibu", "Sei Shōnagon", "Matsuo Bashō", "Lady Sarashina"])
M(8, "science", "Which logician proved the incompleteness theorems in 1931?", ["Kurt Gödel", "David Hilbert", "Bertrand Russell", "Alan Turing"])
M(8, "art", "Which Italian painter created \"The Calling of Saint Matthew\" around 1600?", ["Caravaggio", "Titian", "Tintoretto", "Raphael"])
TF(8, "world", "The philosopher Baruch Spinoza was born in Amsterdam.", True)
TF(8, "history", "The Peloponnesian War ended with the victory of Athens over Sparta.", False)
P(8, "rene_descartes", ["René Descartes", "Blaise Pascal", "Baruch Spinoza", "Cardinal Richelieu"])
P(8, "erasmus", ["Erasmus", "Martin Luther", "Thomas More", "John Calvin"])
S(8, "history", "In what year did the First Council of Nicaea take place?", 100, 800, 325, "year")
S(8, "science", "In what year did Copernicus publish \"On the Revolutions of the Heavenly Spheres\"?", 1400, 1700, 1543, "year")

# ================================================================ complément par matière
# (manches thématiques : au moins une vingtaine de questions par matière)

# ---------------------------------------------------------------- art
M(1, "art", "Which artist is famous for his paintings of sunflowers?", ["Vincent van Gogh", "Claude Monet", "Pablo Picasso", "Rembrandt"])
M(2, "art", "In which city is the Louvre museum?", ["Paris", "London", "Rome", "Madrid"])
TF(2, "art", "Michelangelo sculpted the statue of David.", True)
M(3, "art", "Which painter is known for his water lilies painted at Giverny?", ["Claude Monet", "Auguste Renoir", "Edgar Degas", "Paul Gauguin"])
M(4, "art", "Which art movement is Salvador Dalí associated with?", ["Surrealism", "Cubism", "Impressionism", "Pop art"])
S(4, "art", "In what year did Leonardo da Vinci die?", 1400, 1600, 1519, "year")
TF(5, "art", "Andy Warhol was a leading figure of Pop art.", True)
M(5, "art", "Who painted \"The Birth of Venus\" in the 1480s?", ["Sandro Botticelli", "Raphael", "Titian", "Giotto"])
M(6, "art", "Which architect designed the Sagrada Família in Barcelona?", ["Antoni Gaudí", "Le Corbusier", "Frank Lloyd Wright", "Oscar Niemeyer"])
S(6, "art", "In what year was the Eiffel Tower completed?", 1800, 1950, 1889, "year")
TF(7, "art", "\"Las Meninas\" was painted by Francisco Goya.", False)
M(8, "art", "Which Japanese artist created the print \"The Great Wave off Kanagawa\"?", ["Katsushika Hokusai", "Utagawa Hiroshige", "Kitagawa Utamaro", "Tawaraya Sōtatsu"])

# ---------------------------------------------------------------- littérature
M(1, "literature", "Who wrote the Harry Potter novels?", ["J. K. Rowling", "J. R. R. Tolkien", "Roald Dahl", "C. S. Lewis"])
TF(1, "literature", "\"The Odyssey\" tells the story of Odysseus's journey home.", True)
M(2, "literature", "Which detective was created by Arthur Conan Doyle?", ["Sherlock Holmes", "Hercule Poirot", "Philip Marlowe", "Miss Marple"])
TF(2, "literature", "Charles Dickens wrote \"Oliver Twist\".", True)
M(3, "literature", "Who wrote \"Les Misérables\"?", ["Victor Hugo", "Émile Zola", "Alexandre Dumas", "Gustave Flaubert"])
TF(3, "literature", "\"Moby-Dick\" is about the hunt for a great white whale.", True)
M(4, "literature", "Which Russian author wrote \"War and Peace\"?", ["Leo Tolstoy", "Fyodor Dostoevsky", "Anton Chekhov", "Ivan Turgenev"])
M(5, "literature", "Who wrote \"One Hundred Years of Solitude\"?", ["Gabriel García Márquez", "Jorge Luis Borges", "Mario Vargas Llosa", "Pablo Neruda"])
S(5, "literature", "In what year was the first part of \"Don Quixote\" published?", 1400, 1800, 1605, "year")
M(6, "literature", "Which poet wrote \"The Waste Land\"?", ["T. S. Eliot", "W. B. Yeats", "Ezra Pound", "W. H. Auden"])
M(7, "literature", "Who wrote \"In Search of Lost Time\"?", ["Marcel Proust", "André Gide", "Albert Camus", "Stendhal"])
TF(8, "literature", "Fyodor Dostoevsky wrote \"Fathers and Sons\".", False)

# ---------------------------------------------------------------- mythologie
TF(1, "mythology", "In Greek mythology, Poseidon is the god of the sea.", True)
M(1, "mythology", "Which Greek hero had to complete a series of labours as a penance?", ["Heracles", "Achilles", "Theseus", "Jason"])
M(2, "mythology", "Who is the Roman god of war?", ["Mars", "Jupiter", "Neptune", "Apollo"])
TF(2, "mythology", "In Greek mythology, Pandora opened a jar that released evils into the world.", True)
M(3, "mythology", "Which creature posed a riddle to Oedipus at the gates of Thebes?", ["The Sphinx", "The Minotaur", "The Chimera", "The Hydra"])
M(3, "mythology", "In Egyptian mythology, who is the god of the Sun?", ["Ra", "Osiris", "Anubis", "Thoth"])
TF(3, "mythology", "The Minotaur lived in a labyrinth on the island of Crete.", True)
M(4, "mythology", "Who is the chief god in Norse mythology?", ["Odin", "Thor", "Loki", "Freyr"])
TF(4, "mythology", "In Greek mythology, Achilles was invulnerable except for his heel.", True)
S(4, "mythology", "How many Muses are there in Greek mythology?", 1, 20, 9, "Muses")
M(5, "mythology", "Which Greek goddess sprang fully grown from the head of Zeus?", ["Athena", "Aphrodite", "Artemis", "Hera"])
M(5, "mythology", "In Greek mythology, who was condemned to roll a boulder up a hill for eternity?", ["Sisyphus", "Tantalus", "Prometheus", "Atlas"])
TF(6, "mythology", "In Norse mythology, Ragnarök is the name of Odin's eight-legged horse.", False)
M(6, "mythology", "In Egyptian mythology, which goddess reassembled the body of Osiris?", ["Isis", "Hathor", "Bastet", "Nut"])
M(7, "mythology", "In Aztec mythology, which god is known as the \"Feathered Serpent\"?", ["Quetzalcoatl", "Huitzilopochtli", "Tezcatlipoca", "Tlaloc"])
M(8, "mythology", "In Greek mythology, which Titaness is the goddess of memory and mother of the Muses?", ["Mnemosyne", "Themis", "Rhea", "Tethys"])
TF(8, "mythology", "The Bhagavad Gita is part of the Ramayana.", False)

# ---------------------------------------------------------------- comprendre le monde
M(1, "world", "What is the capital of the United States?", ["Washington, D.C.", "New York", "Los Angeles", "Chicago"])
TF(1, "world", "The euro is the currency used in Japan.", False)
M(2, "world", "Which organization was founded in 1945 to maintain international peace?", ["The United Nations", "NATO", "The European Union", "The League of Nations"])
TF(2, "world", "The word \"democracy\" comes from Greek words meaning \"rule by the people\".", True)
M(3, "world", "Which ancient Greek philosopher was sentenced to death by drinking hemlock?", ["Socrates", "Plato", "Aristotle", "Diogenes"])
M(3, "world", "Who wrote \"The Communist Manifesto\" with Friedrich Engels?", ["Karl Marx", "Vladimir Lenin", "Adam Smith", "Jean-Jacques Rousseau"])
TF(4, "world", "Inflation means that prices in general are falling.", False)
S(4, "world", "How many member states does the United Nations have?", 100, 250, 193, "states")
M(5, "world", "Which philosopher wrote \"The Republic\"?", ["Plato", "Aristotle", "Cicero", "Epicurus"])
M(5, "world", "Which thinker wrote \"The Prince\", a treatise on political power?", ["Niccolò Machiavelli", "Thomas Hobbes", "John Locke", "Montesquieu"])
S(5, "world", "In what year was the Universal Declaration of Human Rights adopted?", 1900, 2000, 1948, "year")
M(6, "world", "Who is the author of \"Leviathan\" (1651)?", ["Thomas Hobbes", "John Locke", "David Hume", "Francis Bacon"])
TF(6, "world", "\"I think, therefore I am\" is a statement by René Descartes.", True)
M(7, "world", "Which philosopher wrote \"Thus Spoke Zarathustra\"?", ["Friedrich Nietzsche", "Martin Heidegger", "Søren Kierkegaard", "Arthur Schopenhauer"])
TF(7, "world", "John Maynard Keynes argued that governments should never intervene in the economy.", False)
M(8, "world", "Which philosopher wrote \"Being and Time\" (1927)?", ["Martin Heidegger", "Edmund Husserl", "Jean-Paul Sartre", "Ludwig Wittgenstein"])
