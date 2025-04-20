<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;

class AttendanceController extends Controller
{
    public function index($sessionId)
{
    $attendances = Attendance::where('session_id', $sessionId)->with('student')->get();
    return response()->json($attendances);
}

public function store(Request $request, $sessionId)
{
    $data = $request->validate([
        'student_id' => 'required|exists:students,id',
        'session_id' => 'required|exists:session,id',
    ]);

    $data['session_id'] = $sessionId;

    $attendance = Attendance::create($data);

    return response()->json($attendance, 201);
}

public function update(Request $request, $sessionId, $attendanceId)
{
    $attendance = Attendance::where('session_id', $sessionId)->findOrFail($attendanceId);

    $attendance->update($request->only('status'));

    return response()->json($attendance);
}

public function destroy($sessionId, $attendanceId)
{
    $attendance = Attendance::where('session_id', $sessionId)->findOrFail($attendanceId);
    $attendance->delete();

    return response()->json(null, 204);
}

}
