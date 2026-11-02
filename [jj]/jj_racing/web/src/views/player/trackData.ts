import { useEffect, useState } from "react";
import { fetchNui } from "@/lib/nui";
import type { NuiResponse, Paginated, TrackDetail, TrackSummary } from "@/lib/types";

// Cache de detalle por id+version (las miniaturas del catalogo piden la ruta de cada circuito)
const cache = new Map<string, Promise<NuiResponse<TrackDetail>>>();

export function clearTrackCache() {
  cache.clear();
}

export function loadTrack(id: number, version: number): Promise<NuiResponse<TrackDetail>> {
  const key = `${id}:${version}`;
  let p = cache.get(key);
  if (!p) {
    p = fetchNui<TrackDetail>("getTrack", { id });
    cache.set(key, p);
    void p.then((r) => !r.ok && cache.delete(key));
  }
  return p;
}

export function useTrackDetail(id: number, version: number): TrackDetail | null {
  const [detail, setDetail] = useState<TrackDetail | null>(null);
  useEffect(() => {
    let alive = true;
    setDetail(null);
    void loadTrack(id, version).then((r) => alive && r.ok && setDetail(r.data));
    return () => {
      alive = false;
    };
  }, [id, version]);
  return detail;
}

/** Recorre todas las paginas de listTracks (selectores de circuito) */
export async function loadAllTracks(filter: (t: TrackSummary) => boolean = () => true): Promise<NuiResponse<TrackSummary[]>> {
  const out: TrackSummary[] = [];
  for (let page = 1; page <= 50; page++) {
    const res = await fetchNui<Paginated<TrackSummary>>("listTracks", { page, sort: "name" });
    if (!res.ok) return res;
    out.push(...res.data.items);
    if (page * res.data.pageSize >= res.data.total) break;
  }
  return { ok: true, data: out.filter(filter) };
}
