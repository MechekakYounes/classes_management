<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use PhpOffice\PhpSpreadsheet\IOFactory;
use App\Models\Student;


class StudentController extends Controller
{
public function import(Request $request)
{
    $request->validate([
        'file' => 'required|file|mimes:xls,xlsx,csv'
    ]);

    $filePath = $request->file('file')->getRealPath();

    $spreadsheet = IOFactory::load($filePath);
    $sheet = $spreadsheet->getActiveSheet();
    $rows = $sheet->toArray();

    // Assume first row is the header
    $header = array_map('strtolower', $rows[0]);
    unset($rows[0]);

    foreach ($rows as $row) {
        $data = array_combine($header, $row);

        Student::create([
            'fname'     => $data['family name'] ?? '',
            'name'    => $data['name'] ?? '',
        ]);
    }

    return response()->json(['message' => 'Students imported successfully']);
}

public function index(Request $request){
    $students = Student::where('group_id',$request->group_id)->get();
    return response()->json($students);
}
}
