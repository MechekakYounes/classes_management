<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Commune;

class CommuneController extends Controller
{
    /**
     * Display a listing of the resource.
     */
    public function index(Request $request)
    {
        $query = Commune::query();
        if ($request->has('wilaya_id')) {
            $query->where('wilaya_id', $request->query('wilaya_id'));
        }
        $communes = $query->get();
        return response()->json($communes);
    }

    /**
     * Show the form for creating a new resource.
     */
    public function create()
    {
        //
    }

    /**
     * Store a newly created resource in storage.
     */
    public function store(Request $request)
    {
        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'wilaya_id' => 'required|integer',
        ]);

        $commune = Commune::create($validated);

        return response()->json($commune, 201);
    }

    /**
     * Display the specified resource.
     */
    public function show(string $id)
    {
        $commune = Commune::find($id);

        if (!$commune) {
            return response()->json(['message' => 'Commune not found'], 404);
        }

        return response()->json($commune);
    }

    /**
     * Show the form for editing the specified resource.
     */
    public function edit(string $id)
    {
        //
    }

    /**
     * Update the specified resource in storage.
     */
    public function update(Request $request, string $id)
    {
        $commune = Commune::find($id);

        if (!$commune) {
            return response()->json(['message' => 'Commune not found'], 404);
        }

        $validated = $request->validate([
            'name' => 'required|string|max:255',
            'wilaya_id' => 'required|integer',
        ]);

        $commune->update($validated);

        return response()->json($commune);
    }

    /**
     * Remove the specified resource from storage.
     */
    public function destroy(string $id)
    {
        $commune = Commune::find($id);

        if (!$commune) {
            return response()->json(['message' => 'Commune not found'], 404);
        }

        $commune->delete();

        return response()->json(['message' => 'Commune deleted successfully']);
    }
}
