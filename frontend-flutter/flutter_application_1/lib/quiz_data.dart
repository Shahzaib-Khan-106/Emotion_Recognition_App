import 'dart:math';

class QuizData {
  // 😊 Only the 6 BASIC, easy-to-recognise emotions
  static const List<String> easyEmotions = [
    "Happy",
    "Sad",
    "Angry",
    "Scared",
    "Surprised",
    "Disgusted",
  ];

  // Kept so any other screen that used the old name keeps working
  static final List<String> allGlobalEmotions = easyEmotions;

  // 🙂 A clear face for each emotion (shown next to the answer buttons)
  static const Map<String, String> emotionFaces = {
    "Happy": "😊",
    "Sad": "😢",
    "Angry": "😠",
    "Scared": "😨",
    "Surprised": "😲",
    "Disgusted": "🤢",
  };

  static String faceFor(String emotion) => emotionFaces[emotion] ?? "🙂";

  // 🧠 Question bank: 36 simple questions (6 for each emotion)
  static final List<Map<String, dynamic>> masterQuestionBank = [
    // ---------- HAPPY ----------
    {
      "emoji": "🎂",
      "words": "\"It is my birthday and I got a big cake! I am smiling so much!\"",
      "correct": "Happy"
    },
    {
      "emoji": "🐶",
      "words": "\"My puppy ran to me and wagged its tail. I love playing with him!\"",
      "correct": "Happy"
    },
    {
      "emoji": "⚽",
      "words": "\"My team won the game and we are all cheering and laughing!\"",
      "correct": "Happy"
    },
    {
      "emoji": "🎁",
      "words": "\"Mom gave me my favorite toy as a gift. Thank you, Mom!\"",
      "correct": "Happy"
    },
    {
      "emoji": "🏖️",
      "words": "\"We are playing at the beach with all my friends. This is so much fun!\"",
      "correct": "Happy"
    },
    {
      "emoji": "🍦",
      "words": "\"I got a big ice cream on a sunny day. Yummy!\"",
      "correct": "Happy"
    },

    // ---------- SAD ----------
    {
      "emoji": "🧸",
      "words": "\"I lost my favorite toy and I cannot find it anywhere.\"",
      "correct": "Sad"
    },
    {
      "emoji": "👋",
      "words": "\"My best friend is moving far away. I will miss him so much.\"",
      "correct": "Sad"
    },
    {
      "emoji": "🐟",
      "words": "\"My pet fish died today. I feel like crying.\"",
      "correct": "Sad"
    },
    {
      "emoji": "🎈",
      "words": "\"My balloon flew away into the sky. I want to cry.\"",
      "correct": "Sad"
    },
    {
      "emoji": "🏠",
      "words": "\"Everyone went out to play and I am left alone at home.\"",
      "correct": "Sad"
    },
    {
      "emoji": "🍦",
      "words": "\"My ice cream fell on the ground and now I have nothing.\"",
      "correct": "Sad"
    },

    // ---------- ANGRY ----------
    {
      "emoji": "💥",
      "words": "\"My brother broke my toy on purpose! I am so mad!\"",
      "correct": "Angry"
    },
    {
      "emoji": "🧱",
      "words": "\"Someone knocked down the tower I built all day. I want to shout!\"",
      "correct": "Angry"
    },
    {
      "emoji": "🎮",
      "words": "\"He took my game and will not give it back. I am very mad!\"",
      "correct": "Angry"
    },
    {
      "emoji": "🖍️",
      "words": "\"My sister scribbled all over my drawing. My fists are tight and my face is hot!\"",
      "correct": "Angry"
    },
    {
      "emoji": "🚫",
      "words": "\"They pushed me and did not say sorry. I am really angry!\"",
      "correct": "Angry"
    },
    {
      "emoji": "🍪",
      "words": "\"He ate my cookie without asking. That is not fair! I am so mad!\"",
      "correct": "Angry"
    },

    // ---------- SCARED ----------
    {
      "emoji": "🌑",
      "words": "\"The lights went out and it is very dark. I feel afraid.\"",
      "correct": "Scared"
    },
    {
      "emoji": "🐕",
      "words": "\"A big dog is barking loudly at me. I want to run away!\"",
      "correct": "Scared"
    },
    {
      "emoji": "⛈️",
      "words": "\"There is loud thunder and lightning. I am hiding under my blanket.\"",
      "correct": "Scared"
    },
    {
      "emoji": "🛒",
      "words": "\"I am lost in a big store and cannot find Mom. My heart is pounding.\"",
      "correct": "Scared"
    },
    {
      "emoji": "🌉",
      "words": "\"I am standing on a very high bridge and my legs are shaking.\"",
      "correct": "Scared"
    },
    {
      "emoji": "👻",
      "words": "\"I heard a strange noise in my room at night. I am too afraid to look.\"",
      "correct": "Scared"
    },

    // ---------- SURPRISED ----------
    {
      "emoji": "🎉",
      "words": "\"Everyone jumped out and shouted 'Surprise!' at my party. I did not expect that!\"",
      "correct": "Surprised"
    },
    {
      "emoji": "🐰",
      "words": "\"I opened the box and a puppy popped out! Wow, I did not expect that!\"",
      "correct": "Surprised"
    },
    {
      "emoji": "🚪",
      "words": "\"I opened the door and my grandma was standing there! I thought she was far away!\"",
      "correct": "Surprised"
    },
    {
      "emoji": "🎩",
      "words": "\"The magician pulled a coin out of my ear. How did he do that?!\"",
      "correct": "Surprised"
    },
    {
      "emoji": "🌈",
      "words": "\"I looked up and suddenly saw a huge rainbow. Wow, I did not see that coming!\"",
      "correct": "Surprised"
    },
    {
      "emoji": "📬",
      "words": "\"I opened the mail and found a letter I was not expecting at all!\"",
      "correct": "Surprised"
    },

    // ---------- DISGUSTED ----------
    {
      "emoji": "🥛",
      "words": "\"The milk is old and smells really bad. Yuck!\"",
      "correct": "Disgusted"
    },
    {
      "emoji": "🪰",
      "words": "\"There are flies all over the garbage. Eww!\"",
      "correct": "Disgusted"
    },
    {
      "emoji": "🍲",
      "words": "\"I found a hair in my soup. Eww, I cannot eat this!\"",
      "correct": "Disgusted"
    },
    {
      "emoji": "🧦",
      "words": "\"A very smelly dirty sock was right next to my nose. Yuck!\"",
      "correct": "Disgusted"
    },
    {
      "emoji": "🍌",
      "words": "\"I touched a slimy, rotten banana. Eww!\"",
      "correct": "Disgusted"
    },
    {
      "emoji": "🥦",
      "words": "\"I tasted a food that smells terrible. Yuck, take it away!\"",
      "correct": "Disgusted"
    },
  ];

  /// 🎲 Returns [questionCount] questions, BALANCED across the 6 emotions
  /// (so every emotion is practised about equally), in random order.
  /// Each question gets a shuffled "options" list: the correct emotion plus
  /// [optionCount] - 1 other basic emotions (all clearly different).
  static List<Map<String, dynamic>> getRandomQuizSet({
    int questionCount = 10,
    int optionCount = 4,
  }) {
    final random = Random();

    // Group questions by emotion and shuffle each group
    final Map<String, List<Map<String, dynamic>>> byEmotion = {
      for (final e in easyEmotions) e: [],
    };
    for (final q in masterQuestionBank) {
      byEmotion[q["correct"] as String]!.add(q);
    }
    for (final list in byEmotion.values) {
      list.shuffle(random);
    }

    // Round-robin pick so emotions are evenly mixed
    final List<Map<String, dynamic>> picked = [];
    final total = masterQuestionBank.length;
    final target = min(questionCount, total);
    while (picked.length < target) {
      final order = List<String>.from(easyEmotions)..shuffle(random);
      for (final emotion in order) {
        if (picked.length >= target) break;
        final list = byEmotion[emotion]!;
        if (list.isNotEmpty) picked.add(list.removeLast());
      }
    }
    picked.shuffle(random);

    return picked.map((q) {
      final correct = q["correct"] as String;
      return {
        ...q,
        "options": _buildOptions(correct, optionCount, random),
      };
    }).toList();
  }

  static List<String> _buildOptions(
      String correct, int optionCount, Random random) {
    final others = easyEmotions.where((e) => e != correct).toList()
      ..shuffle(random);
    final options = [correct, ...others.take(optionCount - 1)]..shuffle(random);
    return options;
  }
}