<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class RuanganResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id'                => $this->id_ruangan,
            'kode_ruangan'      => $this->kode_ruangan,
            'name_ruangan'      => $this->name_ruangan,
            'kapasitas'         => $this->kapasitas,
            'fasilitas'         => $this->fasilitasNames(),
            'deskripsi_ruangan' => $this->deskripsi_ruangan,
            'status_ruangan'    => $this->status_ruangan,
            'path_foto' => $this->path_foto
                ? asset('storage/' . $this->path_foto)
                : null,
            'nomor_lantai'      => $this->nomor_lantai,
            'id_gedung'         => $this->id_gedung,
            'name_gedung'       => $this->gedung?->name_gedung ?? '-',

            'pic'               => $this->picUser?->name ?? '-',
            'id_number_pic'     => $this->id_number_pic,
        ];
    }

    /**
     * Nama-nama fasilitas ruangan.
     *
     * Sumber utama adalah relasi `fasilitas`. Namun tabel `ruangans` masih
     * menyimpan kolom lama `fasilitas` (string dipisah koma) yang menimpa
     * akses relasi, sehingga dipakai sebagai fallback agar data lama tetap
     * tampil.
     */
    private function fasilitasNames(): array
    {
        $relation = $this->resource->relationLoaded('fasilitas')
            ? $this->resource->getRelation('fasilitas')
            : null;

        if ($relation && $relation->isNotEmpty()) {
            return $relation->pluck('nama_fasilitas')->all();
        }

        return collect(explode(',', (string) $this->resource->getRawOriginal('fasilitas')))
            ->map(fn (string $item) => trim($item))
            ->filter()
            ->values()
            ->all();
    }
}