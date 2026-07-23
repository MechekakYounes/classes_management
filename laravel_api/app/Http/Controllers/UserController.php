<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\User;
use Illuminate\Support\Facades\Hash;

class UserController extends Controller
{
    // ─── TEACHERS ────────────────────────────────────────────────────────────

    public function getTeachers(Request $request)
    {
        $user = $request->user();
        $query = User::role('teacher')->with(['class', 'group']);

        // Role-based scoping (automatic security)
        if ($user) {
            if ($user->hasRole('admin')) {
                $query->where('wilaya_id', $user->wilaya_id);
            } elseif ($user->hasRole('supervisor')) {
                $query->where('commune_id', $user->commune_id);
            } elseif ($user->hasRole('manager')) {
                $query->where('class_id', $user->class_id);
            }
        }

        // Explicit filter params from the filter dialog
        if ($request->has('wilaya_id'))  $query->where('wilaya_id',  $request->wilaya_id);
        if ($request->has('commune_id')) $query->where('commune_id', $request->commune_id);
        if ($request->has('class_id'))   $query->where('class_id',   $request->class_id);
        if ($request->has('group_id'))   $query->where('group_id',   $request->group_id);

        return response()->json($query->get());
    }

    public function createTeacher(Request $request)
    {
        $request->validate([
            'name'     => 'required|string',
            'username' => 'required|string|unique:users,username',
            'password' => 'required|string|min:4',
            'phone'    => 'nullable|string',
            'group_id' => 'nullable|exists:groups,id',
            'class_id' => 'nullable|exists:classes,id',
        ]);

        $teacher = User::create([
            'name'      => $request->name,
            'username'  => $request->username,
            'password'  => Hash::make($request->password),
            'phone'     => $request->phone,
            'group_id'  => $request->group_id,
            'class_id'  => $request->class_id,
            'commune_id'=> $request->user()?->commune_id,
            'wilaya_id' => $request->user()?->wilaya_id,
            'is_active' => true,
        ]);

        $teacher->assignRole('teacher');

        return response()->json($teacher->load(['class', 'group']), 201);
    }

    public function updateTeacher(Request $request, $id)
    {
        $teacher = User::role('teacher')->findOrFail($id);

        $request->validate([
            'name'     => 'nullable|string',
            'username' => 'nullable|string|unique:users,username,' . $id,
            'password' => 'nullable|string|min:4',
            'phone'    => 'nullable|string',
            'group_id' => 'nullable|exists:groups,id',
            'class_id' => 'nullable|exists:classes,id',
        ]);

        $data = $request->only(['name', 'username', 'phone', 'group_id', 'class_id']);
        if ($request->filled('password')) {
            $data['password'] = Hash::make($request->password);
        }

        $teacher->update($data);

        return response()->json($teacher->fresh()->load(['class', 'group']));
    }

    public function deleteTeacher($id)
    {
        $teacher = User::role('teacher')->findOrFail($id);
        $teacher->delete();
        return response()->json(null, 204);
    }

    // ─── MANAGERS ────────────────────────────────────────────────────────────

    /**
     * Get unassigned managers (managers without an assigned school/class_id)
     */
    public function getUnassignedManagers(Request $request)
    {
        $user = $request->user();
        $query = User::role('manager')->whereNull('class_id');

        if ($user) {
            if ($user->hasRole('admin')) {
                $query->where('wilaya_id', $user->wilaya_id);
            } elseif ($user->hasRole('supervisor')) {
                $query->where('commune_id', $user->commune_id);
            }
        }

        return response()->json($query->get());
    }

    public function getManagers(Request $request)
    {
        $user = $request->user();
        $query = User::role('manager')->with(['class', 'commune']);

        if ($user) {
            if ($user->hasRole('admin')) {
                $query->where('wilaya_id', $user->wilaya_id);
            } elseif ($user->hasRole('supervisor')) {
                $query->where('commune_id', $user->commune_id);
            }
        }

        if ($request->has('commune_id')) $query->where('commune_id', $request->commune_id);
        if ($request->has('class_id'))   $query->where('class_id',   $request->class_id);

        return response()->json($query->get());
    }

    public function createManager(Request $request)
    {
        $request->validate([
            'name'      => 'required|string',
            'username'  => 'required|string|unique:users,username',
            'password'  => 'required|string|min:4',
            'phone'     => 'nullable|string',
            'class_id'  => 'nullable|exists:classes,id',
            'commune_id'=> 'nullable|exists:communes,id',
        ]);

        $manager = User::create([
            'name'      => $request->name,
            'username'  => $request->username,
            'password'  => Hash::make($request->password),
            'phone'     => $request->phone,
            'class_id'  => $request->class_id,
            'commune_id'=> $request->commune_id,
            'wilaya_id' => $request->user()?->wilaya_id,
            'is_active' => true,
        ]);

        $manager->assignRole('manager');

        return response()->json($manager->load(['class', 'commune']), 201);
    }

    public function updateManager(Request $request, $id)
    {
        $manager = User::role('manager')->findOrFail($id);

        $request->validate([
            'name'      => 'nullable|string',
            'username'  => 'nullable|string|unique:users,username,' . $id,
            'password'  => 'nullable|string|min:4',
            'phone'     => 'nullable|string',
            'class_id'  => 'nullable|exists:classes,id',
        ]);

        $data = $request->only(['name', 'username', 'phone', 'class_id']);
        if ($request->filled('password')) {
            $data['password'] = Hash::make($request->password);
        }

        $manager->update($data);

        return response()->json($manager->fresh()->load(['class', 'commune']));
    }

    public function deleteManager($id)
    {
        $manager = User::role('manager')->findOrFail($id);
        $manager->delete();
        return response()->json(null, 204);
    }

    // ─── SUPERVISORS ──────────────────────────────────────────────────────────

    public function getSupervisors(Request $request)
    {
        $user = $request->user();
        $query = User::role('supervisor')->with(['commune', 'wilaya']);

        if ($user && $user->hasRole('admin')) {
            $query->where('wilaya_id', $user->wilaya_id);
        }

        if ($request->has('wilaya_id'))  $query->where('wilaya_id',  $request->wilaya_id);
        if ($request->has('commune_id')) $query->where('commune_id', $request->commune_id);

        return response()->json($query->get());
    }

    public function createSupervisor(Request $request)
    {
        $request->validate([
            'name'      => 'required|string',
            'username'  => 'required|string|unique:users,username',
            'password'  => 'required|string|min:4',
            'phone'     => 'nullable|string',
            'commune_id'=> 'required|exists:communes,id',
            'wilaya_id' => 'nullable|integer',
        ]);

        $supervisor = User::create([
            'name'      => $request->name,
            'username'  => $request->username,
            'password'  => Hash::make($request->password),
            'phone'     => $request->phone,
            'commune_id'=> $request->commune_id,
            'wilaya_id' => $request->wilaya_id ?? $request->user()?->wilaya_id,
            'is_active' => true,
        ]);

        $supervisor->assignRole('supervisor');

        return response()->json($supervisor->load(['commune', 'wilaya']), 201);
    }

    public function updateSupervisor(Request $request, $id)
    {
        $supervisor = User::role('supervisor')->findOrFail($id);

        $request->validate([
            'name'      => 'nullable|string',
            'username'  => 'nullable|string|unique:users,username,' . $id,
            'password'  => 'nullable|string|min:4',
            'phone'     => 'nullable|string',
            'commune_id'=> 'nullable|exists:communes,id',
        ]);

        $data = $request->only(['name', 'username', 'phone', 'commune_id']);
        if ($request->filled('password')) {
            $data['password'] = Hash::make($request->password);
        }

        $supervisor->update($data);

        return response()->json($supervisor->fresh()->load(['commune', 'wilaya']));
    }

    public function deleteSupervisor($id)
    {
        $supervisor = User::role('supervisor')->findOrFail($id);
        $supervisor->delete();
        return response()->json(null, 204);
    }

    // ─── ADMINS ───────────────────────────────────────────────────────────────

    public function getAdmins(Request $request)
    {
        $query = User::role('admin')->with('wilaya');

        if ($request->has('wilaya_id')) $query->where('wilaya_id', $request->wilaya_id);

        return response()->json($query->get());
    }

    public function createAdmin(Request $request)
    {
        $request->validate([
            'name'     => 'required|string',
            'username' => 'required|string|unique:users,username',
            'password' => 'required|string|min:4',
            'phone'    => 'nullable|string',
            'wilaya_id'=> 'required|integer',
        ]);

        $admin = User::create([
            'name'     => $request->name,
            'username' => $request->username,
            'password' => Hash::make($request->password),
            'phone'    => $request->phone,
            'wilaya_id'=> $request->wilaya_id,
            'is_active'=> true,
        ]);

        $admin->assignRole('admin');

        return response()->json($admin->load('wilaya'), 201);
    }

    public function updateAdmin(Request $request, $id)
    {
        $admin = User::role('admin')->findOrFail($id);

        $request->validate([
            'name'     => 'nullable|string',
            'username' => 'nullable|string|unique:users,username,' . $id,
            'password' => 'nullable|string|min:4',
            'phone'    => 'nullable|string',
            'wilaya_id'=> 'nullable|integer',
        ]);

        $data = $request->only(['name', 'username', 'phone', 'wilaya_id']);
        if ($request->filled('password')) {
            $data['password'] = Hash::make($request->password);
        }

        $admin->update($data);

        return response()->json($admin->fresh()->load('wilaya'));
    }

    public function deleteAdmin($id)
    {
        $admin = User::role('admin')->findOrFail($id);
        $admin->delete();
        return response()->json(null, 204);
    }
}
