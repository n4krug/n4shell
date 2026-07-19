.pragma library

"use strict";

// BoxUnion.js
//
// Line-sweep union of axis-aligned rectangles, producing rectilinear polygon
// contours suitable for rendering as QtQuick.Shapes paths.
//
// API:
//   unionRectangles(rects)      -> [ { points: [[x,y],...], isHole: bool }, ... ]
//   rectsFromItems(items, target) -> [ {x,y,w,h}, ... ]   (input shaping helper)
//
// `rects` is an array of { x, y, w, h } with w,h >= 0.
// Returned contours are closed implicitly (last vertex connects to first);
// outer contours are CCW (signed area > 0), holes are CW (signed area < 0).
// Degenerate (zero-area) rectangles are ignored.
//
// Algorithm: coordinate-compress all rect edges onto a grid, mark covered
// cells, emit directed boundary edges with the covered region on the left,
// then chain edges into closed contours. At ambiguous "saddle" vertices
// (two diagonal cells filled, touching only at a corner) the left-turn rule
// is preferred, which treats the diagonal filled cells as separate loops.

function unionRectangles(rects) {
    rects = (rects || []).filter(r => r && r.w > 0 && r.h > 0);
    if (rects.length === 0) return [];

    const xsSet = new Set();
    const ysSet = new Set();
    for (const r of rects) {
        xsSet.add(r.x); xsSet.add(r.x + r.w);
        ysSet.add(r.y); ysSet.add(r.y + r.h);
    }
    const xs = Array.from(xsSet).sort((a, b) => a - b);
    const ys = Array.from(ysSet).sort((a, b) => a - b);
    const xMap = new Map(); xs.forEach((v, i) => xMap.set(v, i));
    const yMap = new Map(); ys.forEach((v, i) => yMap.set(v, i));

    const nx = xs.length;
    const ny = ys.length;

    // cover[i][j] = cell [xs[i],xs[i+1]) x [ys[j],ys[j+1]) is in the union
    const cover = new Array(nx - 1);
    for (let i = 0; i < nx - 1; i++) cover[i] = new Array(ny - 1).fill(false);
    for (const r of rects) {
        const i0 = xMap.get(r.x), i1 = xMap.get(r.x + r.w);
        const j0 = yMap.get(r.y), j1 = yMap.get(r.y + r.h);
        for (let i = i0; i < i1; i++)
            for (let j = j0; j < j1; j++)
                cover[i][j] = true;
    }

    const edges = _collectBoundaryEdges(cover, xs, ys, nx, ny);
    const contours = _chainContours(edges);
    return contours
        .map(pts => _dropCollinear(pts))
        .filter(pts => pts.length >= 3)
        .map(pts => ({ points: pts, isHole: _signedArea(pts) < 0 }));
}

// Removes vertices that lie on the straight segment between their neighbors
// (including the wrap-around across the implicit closing edge), so contours
// contain only true corners. Closed polygon is treated as cyclic.
function _dropCollinear(pts) {
    const n = pts.length;
    if (n < 3) return pts.slice();
    const out = [];
    for (let i = 0; i < n; i++) {
        const a = pts[(i - 1 + n) % n];
        const b = pts[i];
        const c = pts[(i + 1) % n];
        const cross = (b[0] - a[0]) * (c[1] - b[1]) - (b[1] - a[1]) * (c[0] - b[0]);
        if (cross !== 0) out.push(b);
    }
    return out;
}

// --- internal helpers -----------------------------------------------------

function _collectBoundaryEdges(cover, xs, ys, nx, ny) {
    // Each edge is [x0,y0,x1,y1] with the covered region on its left.
    const edges = [];

    // Horizontal edges along y = ys[j], spanning cell column i.
    for (let j = 0; j < ny; j++) {
        for (let i = 0; i < nx - 1; i++) {
            const above = (j < ny - 1) ? cover[i][j] : false;
            const below = (j > 0)     ? cover[i][j - 1] : false;
            if (above === below) continue;
            const y = ys[j], x0 = xs[i], x1 = xs[i + 1];
            if (above) edges.push([x0, y, x1, y]); // covered up -> go +x
            else       edges.push([x1, y, x0, y]); // covered down -> go -x
        }
    }

    // Vertical edges along x = xs[i], spanning cell row j.
    for (let i = 0; i < nx; i++) {
        for (let j = 0; j < ny - 1; j++) {
            const left  = (i > 0)     ? cover[i - 1][j] : false;
            const right = (i < nx - 1) ? cover[i][j]    : false;
            if (left === right) continue;
            const x = xs[i], y0 = ys[j], y1 = ys[j + 1];
            if (left)  edges.push([x, y0, x, y1]); // covered left -> go +y
            else       edges.push([x, y1, x, y0]); // covered right -> go -y
        }
    }
    return edges;
}

function _chainContours(edges) {
    const key = (x, y) => x + "," + y;
    const outgoing = new Map();
    edges.forEach((e, idx) => {
        const k = key(e[0], e[1]);
        if (!outgoing.has(k)) outgoing.set(k, []);
        outgoing.get(k).push(idx);
    });

    const used = new Array(edges.length).fill(false);
    const contours = [];

    for (let start = 0; start < edges.length; start++) {
        if (used[start]) continue;
        const pts = [];
        const startK = key(edges[start][0], edges[start][1]);
        let cur = start;
        let guard = 0;
        while (guard++ < edges.length + 2) {
            used[cur] = true;
            const e = edges[cur];
            pts.push([e[0], e[1]]);
            const endK = key(e[2], e[3]);
            if (endK === startK) break;
            const cands = (outgoing.get(endK) || []).filter(c => !used[c]);
            if (cands.length === 0) break;
            cur = _pickNext(edges, e, cands);
        }
        if (pts.length >= 3) contours.push(pts);
    }
    return contours;
}

function _pickNext(edges, incoming, cands) {
    const di = _dirIndex(incoming[2] - incoming[0], incoming[3] - incoming[1]);
    let best = cands[0];
    let bestRank = Number.POSITIVE_INFINITY;
    for (const c of cands) {
        const ec = edges[c];
        const ci = _dirIndex(ec[2] - ec[0], ec[3] - ec[1]);
        const rank = _turnRank((ci - di + 4) % 4);
        if (rank < bestRank) { bestRank = rank; best = c; }
    }
    return best;
}

// 0 = +x, 1 = +y, 2 = -x, 3 = -y (counterclockwise order)
function _dirIndex(dx, dy) {
    if (dx > 0) return 0;
    if (dx < 0) return 2;
    if (dy > 0) return 1;
    return 3;
}

// Prefer left turn (CCW 90), then right turn (CW 90), then U-turn last.
// A 0 (straight) should never occur at a rectilinear vertex terminator.
function _turnRank(ccwAmount) {
    if (ccwAmount === 1) return 0; // left
    if (ccwAmount === 3) return 1; // right
    return 2;                       // U-turn (2)
}

function _signedArea(pts) {
    let s = 0;
    for (let i = 0; i < pts.length; i++) {
        const a = pts[i];
        const b = pts[(i + 1) % pts.length];
        s += a[0] * b[1] - b[0] * a[1];
    }
    return s / 2;
}

// --- input shaping --------------------------------------------------------

// Maps a list of registered items to {x,y,w,h} rects in `target`'s coordinate
// space by calling each item's rectIn(target). Items lacking rectIn are
// skipped. Pure convenience; unionRectangles is the only thing that needs the
// rects, so callers may build rects any other way instead.
function rectsFromItems(items, target) {
    const out = [];
    for (const item of items || []) {
        if (!item || typeof item.rectIn !== "function") continue;
        const r = item.rectIn(target);
        if (!r) continue;
        out.push({ x: r.x, y: r.y, w: r.w, h: r.h });
    }
    return out;
}

function roundPath(pathCoords, radius, min, max) {
  
    const path = [];
    const curveRadius = radius;

    for (let i = 0; i < pathCoords.length; i++) {

        // Get current point and the next two (start, corner, end)
        const c2Index = (i + 1) % pathCoords.length;
        const c3Index = (i + 2) % pathCoords.length;

        const c1Raw = pathCoords[i];
        const c2Raw = pathCoords[c2Index];
        const c3Raw = pathCoords[c3Index];

        const c1 = { x: c1Raw[0], y: c1Raw[1] }
        const c2 = { x: c2Raw[0], y: c2Raw[1] }
        const c3 = { x: c3Raw[0], y: c3Raw[1] }

        // Vector going from C2 to C1 and from C2 to C3
        const c1c2dx = c1.x - c2.x;
        const c1c2dy = c1.y - c2.y;
        const c3c2dx = c3.x - c2.x;
        const c3c2dy = c3.y - c2.y;

        const angle = Math.abs(Math.atan2(
            c1c2dx * c3c2dy - c1c2dy * c3c2dx,
            c1c2dx * c3c2dx + c1c2dy * c3c2dy
        ));

        // Divide distance by two to allow rounding the next corner as much as this one
        const c2c1Dist = Math.hypot(c1c2dx, c1c2dy) / 2;
        const c2c3Dist = Math.hypot(c3c2dx, c3c2dy) / 2;

        // Clamp radius the the max available
        const clampedRadius = Math.min(radius, c2c1Dist, c2c3Dist);

        // Compute ideal control point distance to create a circle with quadratic bezier curves
        // const idealControlPointDistance = (4 / 3) * Math.tan(Math.PI / (2 * 4)) * clampedRadius;
        const idealControlPointDistance = (4 / 3) * Math.tan(
            Math.PI / (2 * ((2 * Math.PI) / angle))
        ) * clampedRadius * (
                angle < Math.PI / 2
                    ? 1 + Math.cos(angle)
                    : 1
            );

        // Start of the curve
        let c1c2curvePoint = {
            x: c2.x + c1c2dx * clampedRadius / c2c1Dist / 2,
            y: c2.y + c1c2dy * clampedRadius / c2c1Dist / 2,
        }
        // First control point
        let c1c2curveCP = {
            x: c2.x + c1c2dx * (clampedRadius - idealControlPointDistance) / c2c1Dist / 2,
            y: c2.y + c1c2dy * (clampedRadius - idealControlPointDistance) / c2c1Dist / 2
        }
        // End of the curve
        let c3c2curvePoint = {
            x: c2.x + c3c2dx * clampedRadius / c2c3Dist / 2,
            y: c2.y + c3c2dy * clampedRadius / c2c3Dist / 2,
        }
        // Second control point
        let c3c2curveCP = {
            x: c2.x + c3c2dx * (clampedRadius - idealControlPointDistance) / c2c3Dist / 2,
            y: c2.y + c3c2dy * (clampedRadius - idealControlPointDistance) / c2c3Dist / 2,
        }

        // Limit number after floating point
        const limit = point => ({
            x: point.x, // limitPrecision(point.x, 3),
            y: point.y //limitPrecision(point.y, 3)
        });

        c1c2curvePoint = limit(c1c2curvePoint);
        c1c2curveCP = limit(c1c2curveCP);
        c3c2curvePoint = limit(c3c2curvePoint);
        c3c2curveCP = limit(c3c2curveCP)

        // If at last coordinate of polygon, use the end of the curve as
        // the polygon starting point
        if (i === pathCoords.length - 1) {
            path.unshift([c3c2curvePoint.x, c3c2curvePoint.y]);
        }
        
        if (c2.x >= max.x || c2.x <= min.x || c2.y >= max.y || c2.y <= min.y) {
            path.push([c2.x, c2.y])
            continue
        }

        // Draw line from previous point to the start of the curve
        path.push([c1c2curvePoint.x, c1c2curvePoint.y]);

        // Cubic bezier to draw the actual curve
        path.push([c1c2curveCP.x, c1c2curveCP.y, c3c2curveCP.x, c3c2curveCP.y, c3c2curvePoint.x, c3c2curvePoint.y]);

    }

    return path
}