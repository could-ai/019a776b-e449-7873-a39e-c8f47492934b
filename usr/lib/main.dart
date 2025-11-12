import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '顶蘑菇游戏',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        useMaterial3: true,
      ),
      home: const MushroomGame(),
    );
  }
}

class MushroomGame extends StatefulWidget {
  const MushroomGame({super.key});

  @override
  State<MushroomGame> createState() => _MushroomGameState();
}

class _MushroomGameState extends State<MushroomGame> {
  // 玩家位置 (0.0 到 1.0，表示屏幕宽度的比例)
  double playerPosition = 0.5;
  
  // 蘑菇列表 [{x: 位置, y: 高度, speed: 速度}]
  List<Map<String, double>> mushrooms = [];
  
  // 游戏状态
  bool isPlaying = false;
  int score = 0;
  Timer? gameTimer;
  Timer? mushroomSpawnTimer;
  
  // 游戏配置
  final double playerSize = 60.0;
  final double mushroomSize = 50.0;
  final double gravity = 0.015;
  final double hitZoneHeight = 0.85; // 玩家可以顶到蘑菇的区域

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    mushroomSpawnTimer?.cancel();
    super.dispose();
  }

  void startGame() {
    setState(() {
      isPlaying = true;
      score = 0;
      mushrooms.clear();
      playerPosition = 0.5;
    });

    // 游戏主循环
    gameTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      updateGame();
    });

    // 生成蘑菇
    mushroomSpawnTimer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      spawnMushroom();
    });
  }

  void spawnMushroom() {
    final random = Random();
    setState(() {
      mushrooms.add({
        'x': random.nextDouble() * 0.8 + 0.1, // 0.1 到 0.9 之间
        'y': 0.0, // 从顶部开始
        'speed': 0.005 + random.nextDouble() * 0.003, // 随机速度
      });
    });
  }

  void updateGame() {
    setState(() {
      // 更新所有蘑菇的位置
      for (int i = mushrooms.length - 1; i >= 0; i--) {
        mushrooms[i]['y'] = mushrooms[i]['y']! + mushrooms[i]['speed']!;

        // 检测碰撞（玩家顶到蘑菇）
        if (mushrooms[i]['y']! >= hitZoneHeight && 
            mushrooms[i]['y']! <= hitZoneHeight + 0.05 &&
            (mushrooms[i]['x']! - playerPosition).abs() < 0.08) {
          // 顶到了！增加分数并反弹蘑菇
          score++;
          mushrooms[i]['speed'] = -0.01; // 向上反弹
        }

        // 移除掉落到底部的蘑菇
        if (mushrooms[i]['y']! > 1.1) {
          mushrooms.removeAt(i);
        }
        // 移除飞出顶部的蘑菇
        else if (mushrooms[i]['y']! < -0.2) {
          mushrooms.removeAt(i);
        }
      }
    });
  }

  void movePlayer(double delta) {
    setState(() {
      playerPosition = (playerPosition + delta).clamp(0.0, 1.0);
    });
  }

  void stopGame() {
    gameTimer?.cancel();
    mushroomSpawnTimer?.cancel();
    setState(() {
      isPlaying = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.blue.shade200,
              Colors.green.shade300,
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // 分数显示
              Positioned(
                top: 20,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '分数: $score',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),

              // 蘑菇
              ...mushrooms.map((mushroom) {
                return Positioned(
                  left: MediaQuery.of(context).size.width * mushroom['x']! - mushroomSize / 2,
                  top: MediaQuery.of(context).size.height * mushroom['y']!,
                  child: Container(
                    width: mushroomSize,
                    height: mushroomSize,
                    child: const Text(
                      '🍄',
                      style: TextStyle(fontSize: 40),
                    ),
                  ),
                );
              }).toList(),

              // 玩家
              if (isPlaying)
                Positioned(
                  left: MediaQuery.of(context).size.width * playerPosition - playerSize / 2,
                  bottom: 80,
                  child: Container(
                    width: playerSize,
                    height: playerSize,
                    child: const Text(
                      '🐸',
                      style: TextStyle(fontSize: 50),
                    ),
                  ),
                ),

              // 控制按钮区域
              if (isPlaying)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  height: 100,
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => movePlayer(-0.1),
                          onLongPress: () {
                            Timer.periodic(const Duration(milliseconds: 50), (timer) {
                              if (!isPlaying) {
                                timer.cancel();
                                return;
                              }
                              movePlayer(-0.02);
                            });
                          },
                          child: Container(
                            color: Colors.blue.withOpacity(0.3),
                            child: const Center(
                              child: Icon(
                                Icons.arrow_back,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => movePlayer(0.1),
                          onLongPress: () {
                            Timer.periodic(const Duration(milliseconds: 50), (timer) {
                              if (!isPlaying) {
                                timer.cancel();
                                return;
                              }
                              movePlayer(0.02);
                            });
                          },
                          child: Container(
                            color: Colors.green.withOpacity(0.3),
                            child: const Center(
                              child: Icon(
                                Icons.arrow_forward,
                                size: 50,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // 开始/结束按钮
              if (!isPlaying)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '🍄 顶蘑菇游戏 🍄',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: 10.0,
                              color: Colors.black45,
                              offset: Offset(2, 2),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (score > 0)
                        Text(
                          '最终分数: $score',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      const SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: startGame,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 50,
                            vertical: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: const Text(
                          '开始游戏',
                          style: TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40),
                        child: Text(
                          '用左右按钮控制青蛙移动\n顶到蘑菇就能得分！',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // 暂停按钮
              if (isPlaying)
                Positioned(
                  top: 20,
                  right: 20,
                  child: IconButton(
                    onPressed: stopGame,
                    icon: const Icon(
                      Icons.pause_circle,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}