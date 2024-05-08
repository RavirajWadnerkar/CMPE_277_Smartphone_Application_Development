// import 'package:http/http.dart' as http;
// import 'dart:convert';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:homedecor/global.dart';  // Ensure this contains your Meshy API Key
//
// // Function to create a 3D model from an image
// Future<String> createImageTo3DTask(String imageUrl) async {
//   final response = await http.post(
//     Uri.parse('https://api.meshy.ai/v1/image-to-3d'),
//     headers: {
//       'Authorization': 'Bearer $meshyApiKey',
//       'Content-Type': 'application/json',
//     },
//     body: jsonEncode({
//       'image_url': imageUrl,
//       'enable_pbr': true,
//     }),
//   );
//
//   if (response.statusCode == 200) {
//     var data = jsonDecode(response.body);
//     return data['result']['task_id']; // Ensure the JSON path is correct based on Meshy's API response
//   } else {
//     throw Exception('Failed to create 3D task: ${response.body}');
//   }
// }
//
// // Function to poll for the completion of the 3D model task
// Future<String> pollForCompletion(String taskId) async {
//   bool isComplete = false;
//   String modelUrl = '';
//
//   while (!isComplete) {
//     final response = await http.get(
//       Uri.parse('https://api.meshy.ai/v1/image-to-3d/$taskId'),
//       headers: {'Authorization': 'Bearer $meshyApiKey'},
//     );
//
//     if (response.statusCode == 200) {
//       var task = jsonDecode(response.body);
//       if (task['status'] == 'SUCCEEDED') {
//         modelUrl = task['model_urls']['obj'];
//         isComplete = true;
//       } else if (task['status'] == 'FAILED') {
//         throw Exception('3D model generation failed');
//       }
//     } else {
//       throw Exception('Failed to retrieve task status: ${response.body}');
//     }
//
//     await Future.delayed(Duration(seconds: 10));  // Poll every 10 seconds
//   }
//
//   return modelUrl;
// }
//
// // High-level function to handle the entire process from image to storing 3D model URL in Firestore
// Future<void> generate3DModel(String imageUrl) async {
//   try {
//     String taskId = await createImageTo3DTask(imageUrl);
//     String modelUrl = await pollForCompletion(taskId);
//
//     // Store the model URL in Firestore
//     await FirebaseFirestore.instance.collection('3dmodels').add({
//       'imageUrl': imageUrl,
//       'modelUrl': modelUrl,
//       'date': Timestamp.now(),
//     });
//   } catch (e) {
//     print('Error generating 3D model: $e');
//   }
// }

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:homedecor/global.dart'; // This should contain your Meshy API key

// Function to create a 3D model from an image
Future<String> createImageTo3DTask(String imageUrl) async {
  final response = await http.post(
    Uri.parse('https://api.meshy.ai/v1/image-to-3d'),
    headers: {
      'Authorization': 'Bearer $meshyApiKey',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'image_url': imageUrl,
      'enable_pbr': true,  // Optionally enable PBR (Physically Based Rendering) maps
    }),
  );

  if (response.statusCode == 200) {
    var data = jsonDecode(response.body);
    return data['result']['task_id'];
  } else {
    throw Exception('Failed to create 3D task with status code ${response.statusCode}: ${response.body}');
  }
}

// Function to poll for the completion of the 3D model task
Future<String> pollForCompletion(String taskId) async {
  while (true) {
    final response = await http.get(
      Uri.parse('https://api.meshy.ai/v1/image-to-3d/$taskId'),
      headers: {'Authorization': 'Bearer $meshyApiKey'},
    );

    if (response.statusCode == 200) {
      var task = jsonDecode(response.body);
      if (task['status'] == 'SUCCEEDED') {
        return task['model_urls']['obj'];  // Assuming the output is in 'obj' format
      } else if (task['status'] == 'FAILED') {
        throw Exception('3D model generation failed');
      }
    } else {
      throw Exception('Failed to retrieve task status with status code ${response.statusCode}: ${response.body}');
    }

    await Future.delayed(Duration(seconds: 10));  // Poll every 10 seconds
  }
}

// High-level function to handle the entire process from image to storing 3D model URL in Firestore
Future<void> generate3DModel(String imageUrl) async {
  try {
    print("Starting 3D model generation for: $imageUrl");
    String taskId = await createImageTo3DTask(imageUrl);
    print("Task ID received: $taskId");
    String modelUrl = await pollForCompletion(taskId);
    print("Model URL received: $modelUrl");

    // Store the model URL in Firestore
    await FirebaseFirestore.instance.collection('3dmodels').add({
      'imageUrl': imageUrl,
      'modelUrl': modelUrl,
      'date': Timestamp.now(),
    });
    print("3D model data stored successfully.");
  } catch (e) {
    print('Error generating 3D model: $e');
    throw e; // Re-throw the error to be caught by the calling function
  }
}


