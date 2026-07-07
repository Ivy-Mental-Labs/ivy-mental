import random
import csv

EMOTIONS = ["happy", "sad", "satisfied", "proud", "anxious", "angry", "afraid", "jealous"]

# Spoken/Audio diary fillers
FILLERS_EN = ["", " like,", " you know,", " so basically,", " um,", " uh,", " kind of,"]
FILLERS_DE = ["", " halt,", " also,", " irgendwie,", " ähm,", " äh,", " sozusagen,"]

# Components for English entries
EN_OPENERS = [
    "Okay, so today was...", "Hey diary, just checking in.", "Wow, I need to talk about today.",
    "Honestly, today was quite a ride.", "So, let's see how to describe today.", "Whew, what a day.",
    "Actually, I need to vent a bit.", "Not sure how to put today into words, but...",
    "Today was... interesting, to say the least.", "Well, today happened.", "Dear diary, it's me again.",
    "Recording this because today was crazy.", "Okay, so here's how today went.", "I just need to record this real quick.",
    "Man, today was something else.", "Let's talk about today's events.", "So, I'm sitting here thinking about today.",
    "Today was a weird mix of things.", "Alright, diary, here's the scoop.", "I need to get today's thoughts down."
]

EN_CLOSERS = [
    "Anyway, I'm going to bed now.", "Hopefully tomorrow will be a bit better.", "That's all for today, I guess.",
    "Glad I got that off my chest.", "Just going to try and relax now.", "Signing off for the night.",
    "Tomorrow is a new day, luckily.", "We'll see how things look in the morning.",
    "I'm just too tired to think about it anymore.", "I hope things turn out okay.", "Anyway, that's my update.",
    "Time to turn off my brain for the night.", "I'm glad today is finally over.", "Looking forward to a fresh start tomorrow.",
    "Guess I'll just sleep on it.", "I need to stop overthinking and just sleep.", "That's pretty much how it went.",
    "Hoping for a calmer day tomorrow.", "Well, that was my day in a nutshell.", "Going to make myself some tea and unwind."
]

EN_TEMPLATES = {
    "happy": {
        "texts": [
            "I had such a great time with my friends today, we couldn't stop laughing.",
            "I received some really good news today and it put a huge smile on my face.",
            "Today was just filled with positive energy and good vibes all around.",
            "I went out for a walk in the sun and felt incredibly joyful and alive.",
            "Everything just clicked today, and I couldn't stop smiling for no reason.",
            "I had the most amazing conversation with someone I haven't spoken to in forever.",
            "Today was one of those days where everything feels beautiful and light.",
            "I got a surprise gift today and it completely made my week.",
            "I felt so much love and support from my family today, it was wonderful.",
            "The weather was perfect and I just felt this deep sense of joy inside.",
            "I laughed so hard my stomach hurt, it was exactly what I needed.",
            "Today felt like a fresh start, and I am so happy about where things are going.",
            "I had a really fun lunch with my coworkers, the energy was so positive.",
            "I finally got to do my favorite hobby today and it brought me so much joy.",
            "Everything went so smoothly today, I just feel genuinely happy.",
            "I felt a sudden burst of optimism today, things are looking up.",
            "I met some new people today and we hit it off immediately, it was great.",
            "Today was filled with small, beautiful moments that made me smile.",
            "I listened to my favorite album on the way home and felt so uplifted.",
            "I just feel incredibly happy and grateful for the people in my life right now."
        ],
        "mood_range": (0.6, 1.0),
        "emotion_bits": [1, 0, 0, 0, 0, 0, 0, 0]
    },
    "sad": {
        "texts": [
            "I felt really lonely today and just couldn't shake off this heavy feeling.",
            "It was a really quiet and depressing day, I just wanted to cry.",
            "Everything felt so gray today, I don't even know why I feel this down.",
            "I received some disappointing news and it made me feel really low.",
            "I missed someone really close to me today, and the emptiness was hard to handle.",
            "It felt like a struggle just to get out of bed this morning.",
            "I felt so isolated from everyone else, like I don't really belong anywhere.",
            "Nothing seemed to interest me today, I just felt emotionally drained.",
            "I ended up crying in the evening because everything just piled up.",
            "Today was just a sad day, and I couldn't find a reason to smile.",
            "I felt like a disappointment to myself and everyone around me.",
            "It was a really gloomy day, both outside and inside my head.",
            "I feel like I'm stuck in this dark place and can't find a way out.",
            "My energy was completely flat today, I just felt a deep sadness.",
            "I had to force myself to smile today, and it was so exhausting.",
            "I felt ignored by the people I care about today, it really hurt.",
            "Everything felt so pointless today, I just want to crawl under the covers.",
            "I kept thinking about past mistakes and just felt this deep regret.",
            "I feel so empty inside, like nothing can really cheer me up right now.",
            "Today was a constant reminder of things that aren't working out in my life."
        ],
        "mood_range": (-1.0, -0.5),
        "emotion_bits": [0, 1, 0, 0, 0, 0, 0, 0]
    },
    "satisfied": {
        "texts": [
            "I had a peaceful day, finished my tasks, and relaxed with a good book.",
            "It was a productive day and everything went exactly as planned.",
            "I feel content with how things are going right now, just calm and steady.",
            "Today was a simple but good day, I did my chores and enjoyed a quiet evening.",
            "I managed to cross everything off my to-do list, which feels so good.",
            "It was a quiet day, no drama, just steady progress on my own terms.",
            "I spent some quality time doing absolutely nothing, and it was perfect.",
            "I feel a nice sense of accomplishment from getting the house cleaned up.",
            "Today was just a solid, balanced day where everything went smoothly.",
            "I had a simple dinner and just felt at peace with where I am in life.",
            "I finally organized my desk, and it feels incredibly satisfying.",
            "I had a good, steady workflow today without any interruptions.",
            "It's nice to just sit back and feel like things are under control.",
            "I took care of some boring tasks today, and I'm glad they are finally done.",
            "I spent a quiet evening relaxing and just felt completely content.",
            "No stress today, just a normal, satisfying routine that felt really grounding.",
            "I had a nice, long walk and cleared my head, it felt really good.",
            "I finished a task I've been putting off for weeks, what a relief.",
            "Today was peaceful, just enjoying the quiet moments without worrying.",
            "I feel like I'm in a stable place right now, and that's more than enough."
        ],
        "mood_range": (0.4, 0.8),
        "emotion_bits": [0, 0, 1, 0, 0, 0, 0, 0]
    },
    "proud": {
        "texts": [
            "I finally finished that difficult project at work and did an amazing job.",
            "I stood up for myself today and felt really strong and confident.",
            "I hit a personal milestone today and I'm really proud of how far I've come.",
            "I solved a really complex problem today that everyone else was struggling with.",
            "I gave a presentation today and it went better than I could have ever hoped.",
            "I stayed disciplined and stuck to my routine even when I wanted to quit.",
            "I received some amazing feedback on my work today, it felt so validating.",
            "I handled a really difficult conversation with a lot of maturity today.",
            "I finally took a big step towards a major goal of mine, it feels great.",
            "I proved to myself today that I am capable of handling tough situations.",
            "I helped someone solve a major issue today and felt really good about my skills.",
            "I stayed calm under pressure today and got the job done successfully.",
            "I overcame a fear of mine today and did the thing anyway, I'm so proud.",
            "My boss praised my work in front of the whole team today, it was amazing.",
            "I made some really tough decisions today, but they were the right ones.",
            "I managed to create something beautiful today through sheer hard work.",
            "I stood by my values today even when it wasn't the easy thing to do.",
            "I did something today that I never thought I'd be able to accomplish.",
            "I worked incredibly hard today and the results really showed.",
            "I feel like I really grew as a person today, and I'm proud of myself."
        ],
        "mood_range": (0.6, 1.0),
        "emotion_bits": [0, 0, 0, 1, 0, 0, 0, 0]
    },
    "anxious": {
        "texts": [
            "I have this constant knot in my stomach about upcoming deadlines.",
            "I couldn't stop overthinking everything today, my mind was racing.",
            "I feel so overwhelmed by all the things I have to do, it's stressing me out.",
            "I kept worrying about the future today and felt really restless.",
            "My heart was beating fast today for no real reason, just pure anxiety.",
            "I feel like something bad is about to happen, and I can't shake the feeling.",
            "I struggled to breathe properly at one point because the pressure was too much.",
            "I felt so tense today, like my body is constantly on high alert.",
            "I kept imagining the worst-case scenarios for my upcoming exams.",
            "The workload is piling up and I just feel paralyzed by the stress.",
            "I felt extremely self-conscious today, worrying about what everyone thought of me.",
            "I couldn't focus on anything today because of this underlying panic.",
            "I feel like I'm losing control of my schedule and my life right now.",
            "Every little task felt like an absolute mountain today, it was exhausting.",
            "I had trouble sleeping last night because my thoughts wouldn't stop spinning.",
            "I feel so insecure about my decisions lately, constantly doubting myself.",
            "The uncertainty of everything right now is really starting to get to me.",
            "I felt like I was constantly on the edge of a panic attack today.",
            "I kept checking my emails and notifications, feeling so nervous about a reply.",
            "I just feel this constant, heavy pressure on my chest all day long."
        ],
        "mood_range": (-0.7, -0.2),
        "emotion_bits": [0, 0, 0, 0, 1, 0, 0, 0]
    },
    "angry": {
        "texts": [
            "I got into a stupid argument today and it made me incredibly angry.",
            "I was so annoyed by how unfair everything was at work today.",
            "I felt this wave of frustration and just wanted to scream.",
            "Someone was incredibly rude to me today and it completely ruined my mood.",
            "I felt so mad at myself for making the same mistake again.",
            "The sheer incompetence of the people I had to deal with today was infuriating.",
            "I had to bite my tongue to keep from yelling at someone today.",
            "I felt completely unappreciated and treated like garbage today.",
            "Everything irritated me today, even the smallest little things.",
            "I got so angry when I found out someone lied to my face.",
            "I felt a lot of resentment building up today over how things are handled.",
            "Someone took credit for my hard work today and I am absolutely furious.",
            "I was in such a bad mood today, everything just made me want to snap.",
            "The traffic and delays today were enough to make me lose my mind.",
            "I felt like screaming at the top of my lungs because of the frustration.",
            "Someone completely ignored my boundaries today and it made me so mad.",
            "I got into a heated fight with my partner and it left me feeling furious.",
            "I felt so impatient and angry at the slow progress of everything today.",
            "I was boiling with rage today after hearing about what they did.",
            "I just feel so bitter and angry about how unfair this situation is."
        ],
        "mood_range": (-1.0, -0.4),
        "emotion_bits": [0, 0, 0, 0, 0, 1, 0, 0]
    },
    "afraid": {
        "texts": [
            "I felt really scared about what might happen next, everything is so uncertain.",
            "I had a minor panic today when I thought about failing.",
            "There's this underlying fear of making mistakes that paralyses me.",
            "I felt physically threatened and unsafe today, it was terrifying.",
            "I got so scared when I heard that strange noise in the house tonight.",
            "The thought of losing my job is keeping me up at night, I'm terrified.",
            "I felt a wave of fear when I realized I might have lost my wallet.",
            "I was terrified of confronting someone today, my hands were literally shaking.",
            "I felt so vulnerable and scared, like I have no protection.",
            "The doctor's appointment today had me absolutely terrified of the results.",
            "I feel so afraid of being alone in the future, it's a scary thought.",
            "I had this sudden panic attack and felt completely terrified for my health.",
            "I felt a deep sense of dread today about where my life is heading.",
            "I was too afraid to speak up in the meeting today, I just froze.",
            "I felt scared of the consequences of my actions today.",
            "The thought of failure is so scary that it makes me want to stop trying.",
            "I felt completely lost and afraid in this new environment today.",
            "I got a sudden scare when a car almost hit me on the crossing.",
            "I feel so fragile and afraid of getting hurt again.",
            "I felt this creeping fear today that everything is going to fall apart."
        ],
        "mood_range": (-1.0, -0.3),
        "emotion_bits": [0, 0, 0, 0, 0, 0, 1, 0]
    },
    "jealous": {
        "texts": [
            "I saw my friends achieving things and felt this bitter envy inside.",
            "I felt really insecure seeing them talk to someone else instead of me.",
            "I couldn't help but compare my life to theirs and felt jealous of their success.",
            "I got jealous when I saw how easily things come to other people.",
            "I saw my partner talking to someone else and felt a sting of jealousy.",
            "I felt so left out today when I saw pictures of their gathering online.",
            "I got jealous of my coworker's promotion, even though they deserved it.",
            "I hate how much I compare myself to people on social media, it makes me so envious.",
            "I felt really threatened when someone else got the attention I wanted.",
            "I got jealous of how happy and successful everyone else seems to be.",
            "I felt a pang of envy when I saw their new car and apartment.",
            "I struggled with jealousy today because my friend got the opportunity I wanted.",
            "I felt insecure and jealous when they didn't invite me to the meeting.",
            "I hate feeling this way, but I was so envious of their vacation photos.",
            "I felt jealous of how confident and popular they are compared to me.",
            "I got jealous when my friend started spending all their time with someone else.",
            "I felt envious of how easy their relationship looks from the outside.",
            "I found myself wishing I had their life today, which made me feel awful.",
            "I felt a sudden rush of jealousy when they praised someone else's work.",
            "I struggled with feelings of inadequacy and envy all day long today."
        ],
        "mood_range": (-0.6, 0.1),
        "emotion_bits": [0, 0, 0, 0, 0, 0, 0, 1]
    }
}

# Components for German entries
DE_OPENERS = [
    "Also, heute war...", "Hallo Tagebuch, kurzes Update von mir.", "Boah, ich muss mir heute mal was von der Seele reden.",
    "Ehrlich gesagt war heute ein ganz schöner Ritt.", "Mal schauen, wie ich heute am besten beschreibe.", "Uff, was für ein Tag.",
    "Eigentlich muss ich einfach mal ein bisschen Dampf ablassen.",
    "Ich weiß gar nicht genau, wie ich heute in Worte fassen soll, aber...",
    "Heute war... gelinde gesagt, sehr interessant.", "Na ja, heute ist einiges passiert.", "Liebes Tagebuch, ich bin's wieder.",
    "Ich nehme das hier auf, weil heute echt verrückt war.", "Okay, also so lief mein Tag heute ab.", "Ich muss das hier kurz mal festhalten.",
    "Mann, heute war echt einiges los.", "Lass uns mal über die heutigen Ereignisse sprechen.",
    "Ich sitze hier gerade und denke über heute nach.", "Heute war irgendwie eine seltsame Mischung.", "Alles klar, Tagebuch, hier ist das Update.",
    "Ich muss meine Gedanken zu heute einfach mal aufschreiben."
]

DE_CLOSERS = [
    "Wie dem auch sei, ich gehe jetzt schlafen.", "Hoffentlich wird morgen ein bisschen besser.", "Das war's dann wohl für heute.",
    "Tut echt gut, das mal ausgesprochen zu haben.", "Ich versuche jetzt einfach, ein bisschen runterzukommen.",
    "Das war mein Tag, ich bin raus für heute.", "Morgen ist zum Glück ein neuer Tag.", "Mal sehen, wie die Welt morgen früh aussieht.",
    "Ich bin einfach zu müde, um weiter darüber nachzudenken.", "Ich hoffe einfach, dass alles gut ausgeht.", "Na ja, das ist jedenfalls mein Update.",
    "Zeit, den Kopf für heute auszuschalten.", "Ich bin echt froh, dass dieser Tag vorbei ist.", "Ich freue mich auf einen Neuanfang morgen.",
    "Ich schlafe jetzt wohl am besten mal drüber.", "Ich muss aufhören zu grübeln und einfach schlafen.", "So lief das heute jedenfalls ab.",
    "Ich hoffe auf einen ruhigeren Tag morgen.", "Tja, das war mein Tag im Großen und Ganzen.", "Ich mache mir jetzt noch einen Tee und entspanne."
]

DE_TEMPLATES = {
    "happy": {
        "texts": [
            "Ich hatte heute so eine tolle Zeit mit meinen Freunden, wir mussten ständig lachen.",
            "Ich habe heute richtig gute Nachrichten bekommen, das hat mir ein breites Lächeln ins Gesicht gezaubert.",
            "Heute war einfach voller positiver Energie und rundum guter Laune.",
            "Ich war heute in der Sonne spazieren und habe mich einfach unglaublich glücklich und lebendig gefühlt.",
            "Heute hat einfach alles gepasst, ich musste ohne Grund die ganze Zeit grinsen.",
            "Ich hatte ein fantastisches Gespräch mit jemandem, von dem ich ewig nichts gehört habe.",
            "Heute war einer dieser Tage, an denen sich alles leicht und schön anfühlt.",
            "Ich habe heute ein kleines Überraschungsgeschenk bekommen, das hat mir die Woche gerettet.",
            "Ich habe heute so viel Liebe und Unterstützung von meiner Familie gespürt, das war wunderschön.",
            "Das Wetter war perfekt und ich hatte einfach diese tiefe Freude in mir.",
            "Ich habe so viel gelacht, dass mir der Bauch wehtat, das hat so gut getan.",
            "Heute fühlte sich wie ein Neuanfang an und ich freue mich auf das, was kommt.",
            "Ich hatte ein super lustiges Mittagessen mit meinen Kollegen, die Stimmung war toll.",
            "Ich konnte heute endlich mal wieder meinem Lieblingshobby nachgehen und hatte so viel Spaß.",
            "Heute lief alles wie am Schnürchen, ich bin einfach rundum glücklich.",
            "Ich habe heute einen richtigen Motivationsschub bekommen, es geht bergauf.",
            "Ich habe heute neue Leute kennengelernt und wir haben uns auf Anhieb verstanden.",
            "Heute war voller kleiner, schöner Momente, die mich glücklich gemacht haben.",
            "Ich habe auf dem Heimweg meine Lieblingsmusik gehört und mich einfach super gefühlt.",
            "Ich bin gerade einfach nur dankbar und glücklich für die tollen Menschen in meinem Leben."
        ],
        "mood_range": (0.6, 1.0),
        "emotion_bits": [1, 0, 0, 0, 0, 0, 0, 0]
    },
    "sad": {
        "texts": [
            "Ich habe mich heute echt einsam gefühlt und konnte dieses schwere Gefühl einfach nicht abschütteln.",
            "Es war ein wirklich trauriger und bedrückender Tag, ich wollte einfach nur weinen.",
            "Alles fühlte sich heute so grau an, ich weiß gar nicht, warum ich so deprimiert bin.",
            "Ich habe eine enttäuschende Nachricht erhalten und das hat meine Stimmung total runtergezogen.",
            "Ich habe heute jemanden sehr vermisst und diese Leere war echt schwer zu ertragen.",
            "Es hat mich heute Überwindung gekostet, überhaupt aus dem Bett aufzustehen.",
            "Ich habe mich heute so ausgeschlossen gefühlt, als würde ich nirgends dazugehören.",
            "Nichts konnte mich heute begeistern, ich habe mich einfach leer und ausgelaugt gefühlt.",
            "Am Abend kamen mir einfach die Tränen, weil alles zu viel wurde.",
            "Heute war einfach ein trauriger Tag und ich konnte keinen Grund zum Lächeln finden.",
            "Ich hatte heute das Gefühl, mich selbst und andere nur zu enttäuschen.",
            "Es war ein trüber Tag, sowohl draußen als auch in meiner Gefühlswelt.",
            "Ich fühle mich, als stecke ich in einem Loch fest und finde den Ausgang nicht.",
            "Meine Energie war heute am Boden, ich habe nur eine tiefe Traurigkeit gespürt.",
            "Ich musste mich heute zwingen zu lächeln, das war unglaublich anstrengend.",
            "Ich fühlte mich heute von den Menschen, die mir wichtig sind, völlig ignoriert.",
            "Alles fühlte sich heute so sinnlos an, ich wollte mich einfach nur verkriechen.",
            "Ich musste heute viel über alte Fehler nachdenken und habe tiefe Reue gespürt.",
            "Ich fühle mich innerlich so leer, nichts kann mich gerade aufheitern.",
            "Der Tag heute war wieder eine Erinnerung an alles, was gerade schiefläuft."
        ],
        "mood_range": (-1.0, -0.5),
        "emotion_bits": [0, 1, 0, 0, 0, 0, 0, 0]
    },
    "satisfied": {
        "texts": [
            "Ich hatte einen friedlichen Tag, habe meine Aufgaben erledigt und mit einem Buch entspannt.",
            "Es war ein produktiver Tag und alles lief genau wie geplant.",
            "Ich bin zufrieden damit, wie die Dinge im Moment laufen, einfach ruhig und stabil.",
            "Heute war ein einfacher, aber guter Tag. Ich habe meinen Haushalt gemacht und einen ruhigen Abend genossen.",
            "Ich habe es geschafft, alles auf meiner To-Do-Liste abzuhaken, das tut echt gut.",
            "Es war ein ruhiger Tag ohne Drama, einfach stetiger Fortschritt in meinem Tempo.",
            "Ich habe heute etwas Zeit mit absolutem Nichtstun verbracht und es war perfekt.",
            "Es gibt mir ein gutes Gefühl, dass ich heute endlich die Wohnung aufgeräumt habe.",
            "Heute war einfach ein solider, ausgeglichener Tag, an dem alles gepasst hat.",
            "Ich hatte ein einfaches Abendessen und war einfach im Reinen mit mir selbst.",
            "Ich habe heute endlich meinen Schreibtisch sortiert, das ist sehr befriedigend.",
            "Ich hatte heute einen guten, gleichmäßigen Arbeitsfluss ohne Störungen.",
            "Es ist schön, sich einfach zurückzulehnen und das Gefühl zu haben, alles im Griff zu haben.",
            "Ich habe heute ein paar lästige Aufgaben erledigt und bin froh, dass sie weg sind.",
            "Ich habe einen ruhigen Abend auf dem Sofa verbracht und war einfach wunschlos glücklich.",
            "Kein Stress heute, einfach eine angenehme Routine, die mir Halt gegeben hat.",
            "Ich habe einen langen Spaziergang gemacht und den Kopf freigekriegt, das tat gut.",
            "Ich habe heute eine Aufgabe beendet, die ich seit Wochen vor mir hergeschoben habe.",
            "Heute war es einfach friedlich, die ruhigen Momente zu genießen, ohne sich zu sorgen.",
            "Ich fühle mich gerade einfach stabil und ausgeglichen, und das reicht mir völlig."
        ],
        "mood_range": (0.4, 0.8),
        "emotion_bits": [0, 0, 1, 0, 0, 0, 0, 0]
    },
    "proud": {
        "texts": [
            "Ich habe endlich dieses schwierige Projekt auf der Arbeit fertiggestellt und es ist super geworden.",
            "Ich habe heute für mich selbst eingestanden und mich richtig stark und selbstbewusst gefühlt.",
            "Ich habe heute einen persönlichen Meilenstein erreicht und bin stolz auf meinen Weg.",
            "Ich habe heute ein wirklich komplexes Problem gelöst, an dem alle anderen verzweifelt sind.",
            "Ich habe heute eine Präsentation gehalten und sie lief besser, als ich je gedacht hätte.",
            "Ich bin heute diszipliniert geblieben und habe mein Training durchgezogen, obwohl ich keine Lust hatte.",
            "Ich habe heute tolles Feedback für meine Arbeit bekommen, das war sehr bestätigend.",
            "Ich habe heute ein schwieriges Gespräch sehr reif und ruhig gemeistert.",
            "Ich habe heute endlich einen großen Schritt in Richtung meines Hauptziels gemacht.",
            "Ich habe mir heute selbst bewiesen, dass ich auch mit schwierigen Situationen klarkomme.",
            "Ich konnte heute jemandem bei einem großen Problem helfen, das war ein gutes Gefühl.",
            "Ich bin heute unter Druck ruhig geblieben und habe die Aufgabe erfolgreich gelöst.",
            "Ich habe heute meine Angst überwunden und die Sache trotzdem durchgezogen, echt stolz.",
            "Mein Chef hat meine Leistung heute vor dem gesamten Team gelobt, das war klasse.",
            "Ich musste heute schwierige Entscheidungen treffen, aber es waren die richtigen.",
            "Ich habe heute durch harte Arbeit etwas wirklich Gutes auf die Beine gestellt.",
            "Ich bin heute meinen Werten treu geblieben, auch wenn es nicht der leichteste Weg war.",
            "Ich habe heute etwas geschafft, von dem ich dachte, dass ich es niemals könnte.",
            "Ich habe mich heute extrem reingehängt und die Ergebnisse können sich echt sehen lassen.",
            "Ich habe das Gefühl, heute als Person gewachsen zu sein, und bin stolz auf mich."
        ],
        "mood_range": (0.6, 1.0),
        "emotion_bits": [0, 0, 0, 1, 0, 0, 0, 0]
    },
    "anxious": {
        "texts": [
            "Ich habe dieses ständige flaue Gefühl im Magen wegen der anstehenden Deadlines.",
            "Ich konnte heute nicht aufhören, über alles nachzugrübeln, meine Gedanken haben sich überschlagen.",
            "Ich fühle mich so überfordert von all den Aufgaben, das stresst mich total.",
            "Ich habe mir heute wieder Sorgen um die Zukunft gemacht und war total unruhig.",
            "Mein Herz hat heute ohne wirklichen Grund total gerast, einfach pure Nervosität.",
            "Ich habe das Gefühl, dass bald etwas schiefgeht, und kann dieses Gefühl nicht abschütteln.",
            "Die Luft wurde mir heute fast zu knapp, weil der Druck einfach zu groß war.",
            "Ich war heute so angespannt, als stünde mein Körper ständig unter Strom.",
            "Ich habe mir heute die schlimmsten Szenarien für meine Prüfungen ausgemalt.",
            "Die Arbeit häuft sich an und ich fühle mich durch den Stress wie gelähmt.",
            "Ich war heute extrem unsicher und habe mir ständig Sorgen gemacht, was andere über mich denken.",
            "Wegen dieser unterschwelligen Panik konnte ich mich heute auf gar nichts konzentrieren.",
            "Ich habe das Gefühl, die Kontrolle über meinen Zeitplan und mein Leben zu verlieren.",
            "Jede kleine Aufgabe kam mir heute wie ein riesiger Berg vor, es war so anstrengend.",
            "Ich konnte letzte Nacht kaum schlafen, weil mein Kopf einfach nicht aufgehört hat zu rotieren.",
            "Ich bin im Moment so unsicher mit meinen Entscheidungen und zweifle ständig an mir.",
            "Die ganze Ungewissheit im Moment macht mir langsam echt zu schaffen.",
            "Ich hatte heute das Gefühl, ständig kurz vor einer Panikattacke zu stehen.",
            "Ich habe heute ständig meine E-Mails gecheckt, weil ich so nervös wegen einer Antwort war.",
            "Ich spüre heute den ganzen Tag diesen ständigen, schweren Druck auf der Brust."
        ],
        "mood_range": (-0.7, -0.2),
        "emotion_bits": [0, 0, 0, 0, 1, 0, 0, 0]
    },
    "angry": {
        "texts": [
            "Ich bin heute in einen blöden Streit geraten und das hat mich unglaublich wütend gemacht.",
            "Ich war so genervt davon, wie ungerecht heute alles im Büro abgelaufen ist.",
            "Ich habe diese Welle von Frustration gespürt und wollte einfach nur laut schreien.",
            "Jemand war heute extrem unhöflich zu mir, das hat mir die Laune komplett verdorben.",
            "Ich war heute so wütend auf mich selbst, weil ich denselben Fehler wieder gemacht habe.",
            "Die Inkompetenz der Leute, mit denen ich heute zu tun hatte, war einfach nur zum Rasen.",
            "Ich musste mir heute echt auf die Zunge beißen, um jemanden nicht anzuschreien.",
            "Ich habe mich heute völlig wertlos gefühlt und wurde wie Dreck behandelt.",
            "Mich hat heute einfach alles aufgeregt, selbst die kleinsten Kleinigkeiten.",
            "Ich war so wütend, als ich erfahren habe, dass ich eiskalt angelogen wurde.",
            "Ich habe heute gemerkt, wie sich immer mehr Groll in mir anstaut über die Zustände hier.",
            "Jemand hat heute die Lorbeeren für meine Arbeit eingeheimst, ich bin absolut wütend.",
            "Ich hatte heute so eine schlechte Laune, ich hätte bei jeder Kleinigkeit ausrasten können.",
            "Der Stau und die Verspätungen heute waren echt genug, um den Verstand zu verlieren.",
            "Ich wollte heute vor lauter Frust einfach nur noch laut gegen die Wand schreien.",
            "Jemand hat heute meine Grenzen völlig missachtet, das hat mich so wütend gemacht.",
            "Ich hatte einen heftigen Streit mit meinem Partner und war danach einfach nur stinksauer.",
            "Ich war heute so ungeduldig und wütend über den langsamen Fortschritt bei allem.",
            "Mir ist heute fast der Kragen geplatzt, als ich gehört habe, was da gelaufen ist.",
            "Ich empfinde gerade einfach nur Bitterkeit und Wut über diese ungerechte Situation."
        ],
        "mood_range": (-1.0, -0.4),
        "emotion_bits": [0, 0, 0, 0, 0, 1, 0, 0]
    },
    "afraid": {
        "texts": [
            "Ich hatte richtig Angst davor, was als nächstes passiert. Alles ist so unsicher.",
            "Ich hatte heute eine kleine Panikattacke, als ich ans Scheitern gedacht habe.",
            "Da ist diese ständige Furcht, Fehler zu machen, die mich regelrecht blockiert.",
            "Ich habe mich heute bedroht und unsicher gefühlt, das war echt beängstigend.",
            "Ich habe heute Nacht ein seltsames Geräusch im Haus gehört und hatte totale Angst.",
            "Der Gedanke, meinen Job zu verlieren, lässt mich nachts nicht schlafen, ich habe nackte Angst.",
            "Ich hatte einen Moment der Panik, als ich dachte, ich hätte meinen Geldbeutel verloren.",
            "Ich hatte heute schreckliche Angst davor, jemanden zu konfrontieren, meine Hände haben gezittert.",
            "Ich habe mich heute so verletzlich und verängstigt gefühlt, völlig schutzlos.",
            "Der Arzttermin heute hat mir eine Riesenangst eingejagt vor den Ergebnissen.",
            "Ich habe solche Angst davor, in der Zukunft allein zu sein, das ist ein gruseliger Gedanke.",
            "Ich hatte plötzlich Herzrasen und panische Angst um meine Gesundheit.",
            "Ich hatte heute ein tiefes Gefühl von Bedrohung, wenn ich an meine Zukunft denke.",
            "Ich hatte heute im Meeting zu große Angst, den Mund aufzumachen, ich war wie erstarrt.",
            "Ich hatte heute große Angst vor den Konsequenzen meiner Fehler.",
            "Der Gedanke ans Scheitern macht mir so viel Angst, dass ich am liebsten aufgeben würde.",
            "Ich habe mich heute in der neuen Umgebung völlig verloren und verängstigt gefühlt.",
            "Ich habe mich total erschrocken, als mich fast ein Auto auf dem Zebrastreifen erfasst hätte.",
            "Ich fühle mich gerade so verletzlich und habe Angst, wieder enttäuscht zu werden.",
            "Ich hatte heute die schleichende Angst, dass mir alles über dem Kopf zusammenbricht."
        ],
        "mood_range": (-1.0, -0.3),
        "emotion_bits": [0, 0, 0, 0, 0, 0, 1, 0]
    },
    "jealous": {
        "texts": [
            "Ich habe gesehen, was meine Freunde erreichen, und habe diese bittere Eifersucht in mir gespürt.",
            "Ich habe mich unsicher gefühlt, als ich sah, dass sie mit jemand anderem geredet haben und nicht mit mir.",
            "Ich konnte nicht aufhören, mein Leben mit ihrem zu vergleichen, und war neidisch auf ihren Erfolg.",
            "Ich war eifersüchtig, als ich gesehen habe, wie leicht anderen manche Dinge fallen.",
            "Ich habe meinen Partner mit jemand anderem reden sehen und habe einen Stich Eifersucht gespürt.",
            "Ich habe mich heute so ausgeschlossen gefühlt, als ich die Fotos von ihrem Treffen online sah.",
            "Ich war eifersüchtig auf die Beförderung meines Kollegen, auch wenn er sie verdient hat.",
            "Ich hasse es, wie sehr ich mich auf Social Media vergleiche, das macht mich so neidisch.",
            "Ich habe mich bedroht gefühlt, als jemand anderes die Aufmerksamkeit bekam, die ich wollte.",
            "Ich war eifersüchtig darauf, wie glücklich und erfolgreich alle anderen wirken.",
            "Ich habe einen Stich Neid verspürt, als ich ihr neues Auto und ihre Wohnung gesehen habe.",
            "Ich hatte heute mit Eifersucht zu kämpfen, weil mein Kumpel die Chance bekommen hat, die ich wollte.",
            "Ich habe mich unsicher und eifersüchtig gefühlt, als sie mich nicht zum Meeting eingeladen haben.",
            "Ich hasse dieses Gefühl, aber ich war so neidisch auf ihre Urlaubsbilder.",
            "Ich war eifersüchtig darauf, wie selbstbewusst und beliebt die anderen im Vergleich zu mir sind.",
            "Ich war eifersüchtig, als mein Freund anfing, seine ganze Zeit mit jemand anderem zu verbringen.",
            "Ich war eifersüchtig darauf, wie einfach deren Beziehung von außen aussieht.",
            "Ich habe mich heute dabei ertappt, wie ich mir ihr Leben gewünscht habe, das war ein mieses Gefühl.",
            "Ich habe eine Welle von Eifersucht gespürt, als jemand anderes für seine Arbeit gelobt wurde.",
            "Ich hatte heute den ganzen Tag mit Gefühlen von Unzulänglichkeit und Neid zu kämpfen."
        ],
        "mood_range": (-0.6, 0.1),
        "emotion_bits": [0, 0, 0, 0, 0, 0, 0, 1]
    }
}


def generate_entry(lang="en", force_emotions=None):
    if force_emotions is None:
        # Select 1 or 2 emotions to combine
        num_emotions = random.choice([1, 1, 2])
        selected_emotions = random.sample(list(EN_TEMPLATES.keys()), num_emotions)
    else:
        selected_emotions = force_emotions

    if lang == "en":
        opener = random.choice(EN_OPENERS)
        closer = random.choice(EN_CLOSERS)
        fillers = FILLERS_EN
        templates = EN_TEMPLATES
    else:
        opener = random.choice(DE_OPENERS)
        closer = random.choice(DE_CLOSERS)
        fillers = FILLERS_DE
        templates = DE_TEMPLATES

    sentences = []
    moods = []
    em_bits = [0] * len(EMOTIONS)

    for em in selected_emotions:
        sentence = random.choice(templates[em]["texts"])
        # Insert a conversational filler in the sentence
        words = sentence.split(" ")
        insert_idx = random.randint(1, max(1, len(words) - 2))
        words.insert(insert_idx, random.choice(fillers))
        sentences.append(" ".join(words).replace(" ,", ",").replace("  ", " "))

        min_m, max_m = templates[em]["mood_range"]
        moods.append(random.uniform(min_m, max_m))

        for idx, bit in enumerate(templates[em]["emotion_bits"]):
            if bit == 1:
                em_bits[idx] = 1

    text = f"{opener} {random.choice(fillers)} {' '.join(sentences)} {closer}"
    text = text.replace(" ,", ",").replace(" .", ".").strip()
    text = " ".join(text.split())  # Clean up duplicate whitespace

    avg_mood = sum(moods) / len(moods)
    # Clip mood to [-1, 1]
    avg_mood = max(-1.0, min(1.0, avg_mood))

    return [text, round(avg_mood, 2)] + em_bits


def generate_csv(file_path, total_count):
    headers = ["diary_entry", "mood"] + EMOTIONS
    rows = []
    
    # Balance German and English 50/50
    en_count = total_count // 2
    de_count = total_count - en_count

    # Ensure every single emotion gets represented at least a few times
    for em in EMOTIONS:
        rows.append(generate_entry(lang="en", force_emotions=[em]))
        rows.append(generate_entry(lang="de", force_emotions=[em]))

    while len(rows) < total_count:
        lang = "en" if len(rows) < en_count + len(EMOTIONS) else "de"
        rows.append(generate_entry(lang=lang))

    # Shuffle to mix languages and emotions
    random.shuffle(rows)

    with open(file_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(headers)
        writer.writerows(rows)

    print(f"Successfully generated {total_count} rows at {file_path}")


if __name__ == "__main__":
    random.seed(42)
    
    # 1000 sample entries
    generate_csv("data/sample.csv", 1000)
    
    # 100 evaluation entries
    generate_csv("data/sample_eval.csv", 100)
