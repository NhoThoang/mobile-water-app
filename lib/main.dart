import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/auth/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/customer/customer_list_screen.dart';
import 'features/customer/customer_provider.dart';
import 'features/reading/reading_provider.dart';
import 'features/payment/bill_list_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuth()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => ReadingProvider()),
      ],
      child: const WaterBillingApp(),
    ),
  );
}

class WaterBillingApp extends StatelessWidget {
  const WaterBillingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Water Billing',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0061FF),
          primary: const Color(0xFF0061FF),
          secondary: const Color(0xFF60EFFF),
        ),
        textTheme: GoogleFonts.outfitTextTheme(),
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.status == AuthStatus.initial) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          
          if (auth.status == AuthStatus.authenticated) {
            // Nếu là admin hoặc worker thì vào danh sách hộ dân, ngược lại vào hóa đơn cá nhân
            if (auth.username == "admin" || auth.role == "worker") {
              return const CustomerListScreen();
            }
            return const BillListScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
