import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

class PieChartWidget extends StatelessWidget {
  Map<String, dynamic> analysisMap;

  PieChartWidget(this.analysisMap, {super.key});

  @override
  Widget build(BuildContext context) {
    return PieChart(
      PieChartData(
        sections: _generateSections(analysisMap),
      ),
    );
  }

  List<PieChartSectionData> _generateSections(Map<String, dynamic> data) {
    List<PieChartSectionData> sections = [];

    data.forEach((category, value) {
      List pr = value['percentage'].split("%");
      if (pr.length > 1) {
        value['percentage'] = double.parse(pr[0]);
      } else {
        value['percentage'] = 0.0;
      }
      sections.add(
        PieChartSectionData(
          color: _randomColor(), // You can customize colors here
          value: value['percentage'],
          title: category,
          radius: 100,
          titleStyle: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      );
    });

    return sections;
  }

  Color _randomColor() {
    return Color((math.Random().nextDouble() * 0xFFFFFF).toInt())
        .withOpacity(1.0);
  }
}
