import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:msaratwasel_services/features/teacher/students/presentation/cubit/my_classes_cubit.dart';
import 'package:msaratwasel_services/features/teacher/students/presentation/cubit/my_classes_state.dart';
import 'package:msaratwasel_services/features/teacher/teacher/domain/entities/classroom_entity.dart';
import 'package:msaratwasel_services/features/teacher/teacher/domain/usecases/get_teacher_classrooms_usecase.dart';

class FakeGetTeacherClassroomsUseCase implements GetTeacherClassroomsUseCase {
  Either<String, List<ClassroomEntity>>? result;

  @override
  Future<Either<String, List<ClassroomEntity>>> call() async {
    return result ?? const Right([]);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('MyClassesCubit & MyClassesState Suite', () {
    late FakeGetTeacherClassroomsUseCase fakeUseCase;
    late MyClassesCubit cubit;

    setUp(() {
      fakeUseCase = FakeGetTeacherClassroomsUseCase();
      cubit = MyClassesCubit(getTeacherClassroomsUseCase: fakeUseCase);
    });

    tearDown(() {
      cubit.close();
    });

    test('1. Initial state is MyClassesInitial', () {
      expect(cubit.state, equals(MyClassesInitial()));
      expect(MyClassesInitial().props, isEmpty);
      expect(MyClassesLoading().props, isEmpty);
    });

    test('2. loadClasses emits Loading and Loaded with classrooms on success', () async {
      final classrooms = [
        const ClassroomEntity(
          id: 'cls_1',
          name: 'فصل الورود',
          nameEn: 'Roses Class',
          grade: 'الأول',
          studentCount: 22,
        ),
      ];
      expect(classrooms.first.getLocalizedName('ar'), 'فصل الورود');
      expect(classrooms.first.getLocalizedName('en'), 'Roses Class');
      fakeUseCase.result = Right<String, List<ClassroomEntity>>(classrooms);

      final states = <MyClassesState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.loadClasses();
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.length, 2);
      expect(states[0], isA<MyClassesLoading>());
      expect(states[1], isA<MyClassesLoaded>());
      final loaded = states[1] as MyClassesLoaded;
      expect(loaded.classrooms.length, 1);
      expect(loaded.classrooms.first.id, 'cls_1');
      expect(loaded.props, [classrooms]);

      await sub.cancel();
    });

    test('3. loadClasses emits Loading and Error on failure', () async {
      fakeUseCase.result = const Left('Failed to fetch classrooms');

      final states = <MyClassesState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.loadClasses();
      await Future.delayed(const Duration(milliseconds: 20));

      expect(states.length, 2);
      expect(states[0], isA<MyClassesLoading>());
      expect(states[1], isA<MyClassesError>());
      final error = states[1] as MyClassesError;
      expect(error.message, 'Failed to fetch classrooms');
      expect(error.props, ['Failed to fetch classrooms']);

      await sub.cancel();
    });
  });
}
