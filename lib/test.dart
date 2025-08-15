// import 'dart:collection';
// import 'dart:io';
//
// main() {
//   //   int num = 10;
//   //   String name = "Nguyen Ngoc Anh";
//   //   double num1 = 3.14;
//   //   bool IsStudent = true;
//   //   print(num);
//   //   num = 10;
//
//   //   print(name);
//   //    print(num);
//   //   print(num1);
//   //   print(IsStudent);
//   // dynamic frName = "Nguyen Van Chien";
//   //  print(frName);
//   //  frName = 100;
//   //  print(frName);
//   // int a = 10;
//   // int b = 20;
//   // var c = a + b;
//   // print(c);
//   //   var d = a - b;
//   //         print("Difference (a - b) = $d");
//
//   //         // Using unary minus
//   //         var e = -d;
//   //         print("Negation -(a - b) = $e");
//
//   //         // Multiplication of a and b
//   //         var f = a * b;
//   //         print("Product (a * b) = $f");
//
//   //         // Division of a and b
//   //         var g = b / a;
//   //         print("Division (b / a) = $g");
//
//   //         // Using ~/ to divide a and b
//   //         var h = b ~/ a;
//   //         print("Quotient (b ~/ a) = $h");
//
//   //         // Remainder of a and b
//   //         var i = b % a;
//   //         print("Remainder (b % a) = $i");
//
//   //  print("Enter your name?");
//   //
//   // String? name = stdin.readLineSync();
//   // int? age = int.parse(stdin.readLineSync()!);
//   //
//   //  // Printing the name
//   //  print("Hello, $name! \nWelcome to GeeksforGeeks!!");
//   //  print("Age :, $age! \nWelcome to GeeksforGeeks!!");
//   //  stdout.write("Nguyen Ngoc Anh");
//
//   // a simple Program
//   // print("Enter first number :");
//   // int? a = int.parse(stdin.readLineSync()!);
//   // print("Enter second number :");
//   // int? b = int.parse(stdin.readLineSync()!);
//   // int c = a+b ;
//   // print("Sum 2 number : $c");
//
//   // List<int> age = [1, 2, 3, 4, 5];
//   // print(age);
//   //
//   // Set<String> name = {"Nguyen", "Ngoc", "Anh"};
//   // name.add("Huy");
//   // name.addAll(["Quan","Anh"]);
//   // print(name);
//   //
//   // Map<String, int> infor = {"Ngoc": 10, "Huy": 21, "Shan": 22};
//   // print(infor.keys);
//   // print(infor.values);
//
//   // String heart = '\u2665';
//   // String smiley = '\u263A';
//   // String star = '\u2605';
//   // String musicNote = '\u266B';
//   // print(heart);
//   // print(smiley);
//   // print(star);
//   // print(musicNote);
//
//   // Set<String> name = {"Tran", "Manh", "Quang"};
//   // var change = name.toList();
//   // print(name);
//   // print(change);
//   // Map<int, String> infor = {1: "Anh", 2: "Chien", 3: "Doi"};
//   // print(infor.values);
//   //
//   // Queue<String> queues = Queue<String>();
//   // queues.add("Anh");
//   // queues.add("Huyen");
//   // print(queues);
//   //
//   // for (sinhVien a in sinhVien.values) {
//   //   print(a);
//   // }
//
//   // var num = 5;
//   // switch(num){
//   //   case 1 :
//   //     print("Truong hop nay sai");
//   //   break;
//   //   case 5:
//   //       print("Truong hop nay dung");
//   //     break;
//   //     default:
//   //       print("Deo co gi");
//   // }
//   // int i = 5;
//   // for (int a = 0 ; a <= i ; a ++){
//   //   print(a);
//   // }
//   //
//   //
//   // var name = 4;
//   // int d = 1;
//   // do {
//   //   print('Hello Anh');
//   //   d++;
//   // } while (d <= name);
//
//   //tong tu a den b
//   // print("Nhap so nguyen to a :");
//   // int? a = int.parse(stdin.readLineSync()!);
//   // print("Nhap so nguyen to b :");
//   // int? b = int.parse(stdin.readLineSync()!);
//   // int sum = 0;
//   // for (int i = a; i <= b; i++) {
//   // sum += i;
//   // }
//   // print("tong tu a den b: ${sum}");
//   //
//   // List<int> numb =[1,2,3,4,5];
//   // print(numb);
//
//   var output = add(4, 5);
//   print(output);
//   non();
// }
//
// enum sinhVien { anh, ngoc, nguyen }
//
// int add(int a, int b) {
//   int result = a + b;
//   return result;
// }
//
// int sub (int c , int d){
//   var result1 = c - d;
//   return result1;
// }
// void non() => print("Nguyen Ngoc Anh");
