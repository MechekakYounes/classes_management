<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Classes;
use App\Models\User;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;

class ClassController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {   
        $query = Classes::with('manager');
        if ($request->has('commune_id')) {
            $query->where('commune_id', $request->query('commune_id'));
        }
        $classes = $query->get();
        return response()->json($classes);
    }

    /**
     * Get schools that currently have no assigned manager.
     */
    public function getUnassignedSchools(Request $request)
    {
        $assignedClassIds = User::role('manager')
            ->whereNotNull('class_id')
            ->pluck('class_id');

        $query = Classes::whereNotIn('id', $assignedClassIds);

        if ($request->has('commune_id')) {
            $query->where('commune_id', $request->query('commune_id'));
        }

        return response()->json($query->get());
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    { 
        $request->validate([
            'name'       => 'required|string',
            'address'    => 'nullable|string',
            'email'      => 'nullable|email',
            'phone'      => 'nullable|string',
            'year'       => 'nullable|string',
            'speciality' => 'nullable|string',
            'level'      => 'nullable|string',
            'semester'   => 'nullable|string',
        ]);

        return DB::transaction(function () use ($request) {
            $class = new Classes();
            $class->name = $request->input('name');
            $class->address = $request->input('address');
            $class->email = $request->input('email');
            $class->phone = $request->input('phone');
            $class->commune_id = $request->input('commune_id');
            $class->save();

            // Handle Existing Manager Selection
            if ($request->has('manager_id') && $request->input('manager_id')) {
                $manager = User::find($request->input('manager_id'));
                if ($manager) {
                    $manager->class_id = $class->id;
                    $manager->save();
                }
            }
            // Handle Inline New Manager Account Creation
            elseif ($request->has('new_manager') && is_array($request->input('new_manager'))) {
                $managerData = $request->input('new_manager');
                if (!empty($managerData['username']) && !empty($managerData['password'])) {
                    $user = User::create([
                        'name' => $managerData['name'] ?? $class->name . ' Manager',
                        'username' => $managerData['username'],
                        'password' => Hash::make($managerData['password']),
                        'phone' => $managerData['phone'] ?? null,
                        'class_id' => $class->id,
                        'commune_id' => $class->commune_id,
                        'is_active' => true,
                    ]);
                    $user->assignRole('manager');
                }
            }

            return response()->json($class->load('manager'), 201);
        });
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        $class = Classes::findOrFail($id);
        $class->update($request->only(['name', 'address', 'email', 'phone', 'commune_id']));
        
        if ($request->has('manager_id')) {
            // Unassign old manager if any
            User::where('class_id', $class->id)->role('manager')->update(['class_id' => null]);

            if ($request->input('manager_id')) {
                User::where('id', $request->input('manager_id'))->update(['class_id' => $class->id]);
            }
        }

        return response()->json($class->load('manager'));
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        Classes::destroy($id);
        return response()->json(null, 204);
    }
}
