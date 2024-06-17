import 'dart:convert';

Map<String, dynamic> schema = {
  "details": {
    "<ingredient-name>": {
      "weight": "<weight>",
      "percentage": "<percentage>",
      "pros": "pros of <ingredient>",
      "cons": "cons of <ingredient>"
    }
  },
  "analysis": "overall analysis of the food"
};

String prompt = """You are an expert nutritionist specializing in food labels. You understand the pros and cons of various ingredients used in food products. Given an image of a food label, provide response in the format: ${jsonEncode(schema)}""";
