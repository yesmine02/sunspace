import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../pages/login/login_page.dart';
import '../pages/register/register_page.dart';
import '../pages/home/home_page.dart';
import '../pages/settings/settings_page.dart';
import '../pages/spaces/spaces_page.dart';
import '../pages/equipments/equipments_page.dart';
import '../pages/users/users_page.dart';
import '../pages/users/students_page.dart';
import '../pages/reservations/reservations_page.dart';
import '../pages/courses/courses_page.dart';
import '../pages/sessions/sessions_page.dart';

import '../pages/assignments/assignments_page.dart';
import '../pages/communication/communication_page.dart';
import '../pages/analytics/analytics_page.dart';
import '../pages/spaces/create_space_page.dart';
import '../pages/spaces/view_space_page.dart';
import '../pages/spaces/edit_space_page.dart';
import '../pages/professional/book_space_page.dart';
import '../pages/professional/my_reservations_page.dart';
import '../pages/professional/subscription_payment_page.dart';
import '../pages/professional/profile_page.dart';
import '../pages/professional/training_page.dart';
import '../pages/student/my_courses_page.dart';
import '../pages/student/course_details_page.dart';
import '../pages/student/study_spaces_page.dart';
import '../pages/student/checkout_page.dart';
import '../pages/association/assoc_trainings_page.dart';
import '../pages/association/assoc_members_page.dart';
import '../pages/association/assoc_budget_page.dart';
import '../pages/association/assoc_list_page.dart';
import '../middleware/auth_middleware.dart';
import '../dashboard_layout.dart';
import 'app_routes.dart';

class AppPages {
  static const INITIAL = AppRoutes.DASHBOARD; 

  static final routes = [
    GetPage(
      name: AppRoutes.LOGIN,
      page: () => LoginPage(),
    ),
    GetPage(
      name: AppRoutes.REGISTER,
      page: () => RegisterPage(),
    ),
    GetPage(
      name: AppRoutes.DASHBOARD,
      page: () => DashboardLayout(child: HomePage()),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.PROFILE,
      page: () => DashboardLayout(child: ProfilePage()),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.SETTINGS,
      page: () => DashboardLayout(child: SettingsPage()),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.SPACES,
      page: () => DashboardLayout(child: const SpacesPage()),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.EQUIPMENTS,
      page: () => DashboardLayout(child: const EquipmentsPage()),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.USERS,
      page: () => DashboardLayout(child: const UsersPage()),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.RESERVATIONS,
      page: () => DashboardLayout(child: const ReservationsPage()),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.COURSES,
      page: () => DashboardLayout(child: const CoursesPage()),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.SESSIONS,
      page: () => DashboardLayout(child: const SessionsPage()),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.TASKS,
      page: () => DashboardLayout(child: const AssignmentsPage()),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.STUDENTS,
      page: () => DashboardLayout(child: const StudentsPage()),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.COMMUNICATION,
      page: () => DashboardLayout(child: const CommunicationPage()),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.ANALYTICS,
      page: () => DashboardLayout(child: const AnalyticsPage()),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.CREATE_SPACE,
      page: () => DashboardLayout(child: const CreateSpacePage()),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.VIEW_SPACE,
      page: () => DashboardLayout(child: const ViewSpacePage()),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.EDIT_SPACE,
      page: () => DashboardLayout(child: const EditSpacePage()),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.BOOK_SPACE,
      page: () => DashboardLayout(child: const BookSpacePage()),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.MY_RESERVATIONS,
      page: () => DashboardLayout(child: const MyReservationsPage()),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.SUBSCRIPTION_PAYMENT,
      page: () => DashboardLayout(child: const SubscriptionPaymentPage()),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.TRAINING,
      page: () => DashboardLayout(child: const TrainingPage()),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.MY_COURSES,
      page: () => DashboardLayout(child: const MyCoursesPage()),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.COURSE_DETAILS,
      page: () => DashboardLayout(child: const CourseDetailsPage()),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.STUDY_SPACES,
      page: () => DashboardLayout(child: const StudySpacesPage()),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.CHECKOUT,
      page: () => DashboardLayout(child: const CheckoutPage()),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.ASSOC_TRAININGS,
      page: () => DashboardLayout(child: const AssocTrainingsPage()),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.ASSOC_MEMBERS,
      page: () => DashboardLayout(child: const AssocMembersPage()),
      middlewares: [AuthMiddleware()],
    ),
    // Placeholders pour les autres routes Association
    GetPage(
      name: AppRoutes.ASSOC_RESERVATIONS,
      page: () => DashboardLayout(child: const Scaffold(body: Center(child: Text('Gestion des Espaces (En développement)')))),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.ASSOC_BUDGET,
      page: () => DashboardLayout(child: const AssocBudgetPage()),
      middlewares: [AuthMiddleware()],
    ),
    GetPage(
      name: AppRoutes.ASSOC_LIST,
      page: () => DashboardLayout(child: const AssocListPage()),
      middlewares: [AuthMiddleware()],
    ),
  ];
}
