import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:emr_homemade/domain/login/login_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
 
    final isDesktop = screenWidth >= 1024;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;
    final isSmallMobile = screenWidth < 360;
    
  
    final scaleFactor = (screenWidth / 1440).clamp(0.7, 1.3);

    return ChangeNotifierProvider(
      create: (_) => LoginProvider(context),
      child: Consumer<LoginProvider>(
        builder: (context, prov, _) {
          return Scaffold(
            backgroundColor: const Color(0xFFF5F7FA),
            body: isDesktop
                ? _buildDesktopLayout(context, prov, scaleFactor, screenWidth)
                : _buildMobileLayout(context, prov, isTablet, isSmallMobile, screenHeight),
          );
        },
      ),
    );
  }

  Widget _buildDesktopLayout(BuildContext context, LoginProvider prov, double scaleFactor, double screenWidth) {
  
    final leftFlex = screenWidth > 1600 ? 6 : 5;
    final rightFlex = screenWidth > 1600 ? 4 : 4;
    
    return Row(
      children: [
 
        Expanded(
          flex: leftFlex,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1E3A8A),
                  Color(0xFF1E40AF),
                  Color(0xFF2563EB),
                ],
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(40 * scaleFactor),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(14 * scaleFactor),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.local_hospital_rounded,
                      size: 48 * scaleFactor,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 32 * scaleFactor),

                  Text(
                    'EMR Homemade',
                    style: GoogleFonts.inter(
                      fontSize: 42 * scaleFactor,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 12 * scaleFactor),

                  Text(
                    'Electronic Medical Record System',
                    style: GoogleFonts.inter(
                      fontSize: 18 * scaleFactor,
                      fontWeight: FontWeight.w400,
                      color: Colors.white.withValues(alpha: 0.9),
                      letterSpacing: 0.2,
                    ),
                  ),
                  SizedBox(height: 32 * scaleFactor),

                  _buildFeatureItem(
                    Icons.insights_rounded,
                    'Data-Driven Decisions',
                    'Gain valuable insights from patient analytics',
                    scaleFactor,
                  ),
                  SizedBox(height: 16 * scaleFactor),
                  _buildFeatureItem(
                    Icons.speed_rounded,
                    'Fast & Efficient',
                    'Streamlined workflow management',
                    scaleFactor,
                  ),
                  SizedBox(height: 16 * scaleFactor),
                  _buildFeatureItem(
                    Icons.integration_instructions_rounded,
                    'Integrated System',
                    'Seamless data integration',
                    scaleFactor,
                  ),

                  const Spacer(),

                  Text(
                    '© 2025 EMR Homemade',
                    style: GoogleFonts.inter(
                      fontSize: 13 * scaleFactor,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        Expanded(
          flex: rightFlex,
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: 440 * scaleFactor,
                  minWidth: 320,
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 40 * scaleFactor,
                  vertical: 32,
                ),
                child: _buildLoginForm(prov, scaleFactor),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
      BuildContext context, LoginProvider prov, bool isTablet, bool isSmallMobile, double screenHeight) {

    final horizontalPadding = isTablet ? 48.0 : (isSmallMobile ? 16.0 : 24.0);
    final verticalPadding = isTablet ? 48.0 : (isSmallMobile ? 24.0 : 32.0);
    final contentPadding = isTablet ? 48.0 : (isSmallMobile ? 20.0 : 24.0);

    final titleFontSize = isTablet ? 36.0 : (isSmallMobile ? 24.0 : 28.0);
    final subtitleFontSize = isTablet ? 16.0 : (isSmallMobile ? 13.0 : 14.0);
    final iconSize = isTablet ? 40.0 : (isSmallMobile ? 32.0 : 36.0);
    
    return SafeArea(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: screenHeight - MediaQuery.of(context).padding.top - MediaQuery.of(context).padding.bottom,
          ),
          child: IntrinsicHeight(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF1E3A8A),
                        Color(0xFF1E40AF),
                        Color(0xFF2563EB),
                      ],
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(isSmallMobile ? 10 : 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.local_hospital_rounded,
                          size: iconSize,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: isTablet ? 24 : (isSmallMobile ? 16 : 20)),

                      Text(
                        'EMR Homemade',
                        style: GoogleFonts.inter(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: -0.5,
                          height: 1.2,
                        ),
                      ),
                      SizedBox(height: isSmallMobile ? 6 : 8),

                      Text(
                        'Electronic Medical Record System',
                        style: GoogleFonts.inter(
                          fontSize: subtitleFontSize,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.9),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(contentPadding),
                    constraints: BoxConstraints(
                      maxWidth: isTablet ? 500 : double.infinity,
                    ),
                    child: _buildLoginForm(prov, 1.0, isSmallMobile: isSmallMobile),
                  ),
                ),

                Padding(
                  padding: EdgeInsets.only(bottom: isSmallMobile ? 16 : 24),
                  child: Text(
                    '© 2025 EMR Homemade',
                    style: GoogleFonts.inter(
                      fontSize: isSmallMobile ? 11 : 12,
                      color: const Color(0xFF94A3B8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm(LoginProvider prov, double scaleFactor, {bool isSmallMobile = false}) {
    final welcomeFontSize = isSmallMobile ? 24.0 : (28 * scaleFactor);
    final subtitleFontSize = isSmallMobile ? 13.0 : (15 * scaleFactor);
    final labelFontSize = isSmallMobile ? 13.0 : (14 * scaleFactor);
    final inputFontSize = isSmallMobile ? 14.0 : (15 * scaleFactor);
    final buttonFontSize = isSmallMobile ? 14.0 : (15 * scaleFactor);
    final iconSize = isSmallMobile ? 18.0 : (20 * scaleFactor);

    final spacing = isSmallMobile ? 0.8 : 1.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome back',
          style: GoogleFonts.inter(
            fontSize: welcomeFontSize,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E293B),
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 8 * spacing),
        Text(
          'Please enter your credentials to access the system',
          style: GoogleFonts.inter(
            fontSize: subtitleFontSize,
            color: const Color(0xFF64748B),
            height: 1.5,
          ),
        ),
        SizedBox(height: 32 * spacing),

        Text(
          'Username',
          style: GoogleFonts.inter(
            fontSize: labelFontSize,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
        SizedBox(height: 8 * spacing),
        TextFormField(
          controller: prov.usernameController,
          style: GoogleFonts.inter(
            fontSize: inputFontSize,
            color: const Color(0xFF1E293B),
          ),
          decoration: InputDecoration(
            hintText: 'Enter your username',
            hintStyle: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: inputFontSize,
            ),
            prefixIcon: Icon(
              Icons.person_outline_rounded,
              color: const Color(0xFF64748B),
              size: iconSize,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16 * scaleFactor,
              vertical: isSmallMobile ? 14 : (16 * scaleFactor),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF2563EB),
                width: 2,
              ),
            ),
          ),
        ),

        SizedBox(height: 20 * spacing),

        Text(
          'Password',
          style: GoogleFonts.inter(
            fontSize: labelFontSize,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF334155),
          ),
        ),
        SizedBox(height: 8 * spacing),
        TextFormField(
          controller: prov.passwordController,
          obscureText: !prov.isPasswordVisible,
          style: GoogleFonts.inter(
            fontSize: inputFontSize,
            color: const Color(0xFF1E293B),
          ),
          decoration: InputDecoration(
            hintText: 'Enter your password',
            hintStyle: GoogleFonts.inter(
              color: const Color(0xFF94A3B8),
              fontSize: inputFontSize,
            ),
            prefixIcon: Icon(
              Icons.lock_outline_rounded,
              color: const Color(0xFF64748B),
              size: iconSize,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                prov.isPasswordVisible
                    ? Icons.visibility_rounded
                    : Icons.visibility_off_rounded,
                color: const Color(0xFF64748B),
                size: iconSize,
              ),
              onPressed: prov.togglePasswordVisibility,
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16 * scaleFactor,
              vertical: isSmallMobile ? 14 : (16 * scaleFactor),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF2563EB),
                width: 2,
              ),
            ),
          ),
        ),
        SizedBox(height: 24 * spacing),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: prov.isLogging ? null : prov.login,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              disabledBackgroundColor: const Color(0xFF94A3B8),
              elevation: 0,
              shadowColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: EdgeInsets.symmetric(
                vertical: isSmallMobile ? 14 : (16 * scaleFactor),
              ),
            ),
            child: prov.isLogging
                ? SizedBox(
                    width: isSmallMobile ? 18 : 20,
                    height: isSmallMobile ? 18 : 20,
                    child: const CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                : Text(
                    'Sign in',
                    style: GoogleFonts.inter(
                      fontSize: buttonFontSize,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
          ),
        ),

        SizedBox(height: 20 * spacing),

        if (prov.errorMessage.isNotEmpty)
          Container(
            padding: EdgeInsets.all(isSmallMobile ? 12 : (14 * scaleFactor)),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFFECACA),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: const Color(0xFFDC2626),
                  size: iconSize,
                ),
                SizedBox(width: 12 * spacing),
                Expanded(
                  child: Text(
                    prov.errorMessage,
                    style: GoogleFonts.inter(
                      color: const Color(0xFFDC2626),
                      fontSize: isSmallMobile ? 13 : (14 * scaleFactor),
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

        SizedBox(height: 24 * spacing),

        Center(
          child: Text(
            'Need help? Contact your system administrator',
            style: GoogleFonts.inter(
              fontSize: isSmallMobile ? 12 : (13 * scaleFactor),
              color: const Color(0xFF94A3B8),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle, double scaleFactor) {
    return Container(
      padding: EdgeInsets.all(16 * scaleFactor),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10 * scaleFactor),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 22 * scaleFactor,
            ),
          ),
          SizedBox(width: 14 * scaleFactor),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14 * scaleFactor,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4 * scaleFactor),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12 * scaleFactor,
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}