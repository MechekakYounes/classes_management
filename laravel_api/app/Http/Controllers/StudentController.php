<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use PhpOffice\PhpSpreadsheet\IOFactory;
use App\Models\Student;


class StudentController extends Controller
{
    public function import(Request $request)
    {
        $students = $request->input('students');
        $groupId = $request->input('group_id'); // 👈 get the group_id from the request
    
        if (!$groupId) {
            return response()->json(['error' => 'group_id is required'], 422);
        }
    
        foreach ($students as $studentData) {
            Student::create([
                'fname' => $studentData['fname'],
                'name' => $studentData['name'],
                'group_id' => $groupId, 
            ]);
        }
    
        return response()->json(['message' => 'Students created successfully'], 201);
    }
    

public function index(Request $request, $groupId = null) {
    $user = $request->user();
    $query = Student::query();

    if ($groupId) {
        $query->where('group_id', $groupId);
    } else {
        // Scoping based on user role
        if ($user->hasRole('super-admin')) {
            // no additional filters
        } elseif ($user->hasRole('admin')) {
            $query->whereHas('group.classes.commune', function ($q) use ($user) {
                $q->where('wilaya_id', $user->wilaya_id);
            });
        } elseif ($user->hasRole('supervisor')) {
            $query->whereHas('group.classes', function ($q) use ($user) {
                $q->where('commune_id', $user->commune_id);
            });
        } elseif ($user->hasRole('manager')) {
            $query->whereHas('group', function ($q) use ($user) {
                $q->where('class_id', $user->class_id);
            });
        } elseif ($user->hasRole('teacher')) {
            $query->where('group_id', $user->group_id);
        }
    }

    // Apply any query param filters from the request
    if ($request->has('wilaya_id') && $request->wilaya_id) {
        $query->whereHas('group.classes.commune', function($q) use ($request) {
            $q->where('wilaya_id', $request->wilaya_id);
        });
    }
    if ($request->has('commune_id') && $request->commune_id) {
         $query->whereHas('group.classes', function($q) use ($request) {
            $q->where('commune_id', $request->commune_id);
        });
    }
    if ($request->has('class_id') && $request->class_id) {
        $query->whereHas('group', function($q) use ($request) {
            $q->where('class_id', $request->class_id);
        });
    }

    $students = $query->with('group.classes.commune.wilaya')->get();

    $students->map(function ($student) {
        $student->group_name = $student->group->name ?? null;
        $student->class_name = $student->group->classes->name ?? null;
        $student->commune_name = $student->group->classes->commune->name ?? null;
        $student->wilaya_name = $student->group->classes->commune->wilaya->name ?? null;
        return $student;
    });

    return response()->json($students);
}


public function store(Request $request)
{
    $validated = $request->validate([
        'name' => 'required|string|max:255',
        'fname' => 'required|string|max:255',
        'group_id' => 'required|exists:groups,id', // if students belong to a group
    ]);

    $student = new Student();
    $student->name = $validated['name'];
    $student->fname = $validated['fname'];
    $student->group_id = $validated['group_id'];
    $student->save();

    return response()->json($student, 201);
}

public function update(Request $request, $id)
{
    $validated = $request->validate([
        'name' => 'sometimes|string|max:255',
        'fname' => 'sometimes|string|max:255',
        'group_id' => 'sometimes|exists:groups,id',
    ]);

    $student = Student::findOrFail($id);
    $student->update($validated);

    return response()->json($student);
}


public function destroy($id)
{
    $student = Student::findOrFail($id);
    $student->delete();

    return response()->json(null, 204);
}



}
