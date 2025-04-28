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
    

public function index(Request $request, $groupId) {


    $students = Student::where('group_id',$groupId)->get();
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
