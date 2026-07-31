/**
 * DoL Stat Panel — console cheat UI without enabling official cheats.
 * Does NOT set V.cheatsEnabled or V.feats.locked (feats stay earnable).
 *
 * Usage: open the game, load a save, F12 → Console → paste this whole file → Enter.
 * Prefer: open START-HERE-Stat-Panel.html → Copy → paste into game console.
 *
 * After time passes the game swaps State.variables — this panel re-binds live V
 * on every slider move and on each passage render (auto reconnect).
 *
 * Close: click X, or run: window.__dolStatPanelRemove && window.__dolStatPanelRemove()
 */
(() => {
	const PANEL_ID = "dol-stat-panel";

	const getV = () => {
		// Always read live state (SugarCube replaces variables after each passage / time pass)
		if (typeof V !== "undefined" && V != null && typeof V.money === "number") return V;
		try {
			const vars = window.SugarCube && window.SugarCube.State && window.SugarCube.State.variables;
			if (vars && typeof vars.money === "number") return vars;
		} catch (_) {}
		return null;
	};

	if (!getV()) {
		console.error("[DoL Panel] No game state. Load a save first, then re-paste.");
		return;
	}

	// Tear down previous panel + listeners if re-pasted
	if (typeof window.__dolStatPanelRemove === "function") {
		try {
			window.__dolStatPanelRemove();
		} catch (_) {}
	}

	const STATE = [
		{ key: "pain", label: "Pain", max: 200 },
		{ key: "arousal", label: "Arousal", max: 10000 },
		{ key: "tiredness", label: "Fatigue", max: 2000 },
		{ key: "stress", label: "Stress", max: (v) => v.stressmax || 10000 },
		{ key: "trauma", label: "Trauma", max: (v) => v.traumamax || 5000 },
		{ key: "control", label: "Control", max: (v) => v.controlmax || 1000 },
		{ key: "drunk", label: "Alcohol", max: 1000 },
		{ key: "drugged", label: "Drugs", max: 1000 },
		{ key: "hallucinogen", label: "Hallucinogens", max: 1000 },
	];

	const maxOf = (s, v) => (typeof s.max === "function" ? s.max(v) : s.max);

	const gameRefresh = () => {
		try {
			if (typeof Wikifier !== "undefined") {
				Wikifier.wikifyEval("<<clamp>><<updatesidebarimg>><<updatesidebarmoney>>");
			} else if (typeof updateSideBarMoney === "function") {
				updateSideBarMoney();
			}
		} catch (e) {
			console.warn("[DoL Panel] UI refresh partial:", e);
		}
	};

	/** Pull live V into sliders / labels */
	const syncFromGame = () => {
		const v = getV();
		const status = document.getElementById("dol-status");
		if (!v) {
			if (status) {
				status.textContent = "disconnected — load a save, then hit Reconnect";
				status.style.color = "#f66";
			}
			return false;
		}
		for (const s of STATE) {
			const el = document.getElementById("dol-sl-" + s.key);
			const lab = document.getElementById("dol-val-" + s.key);
			if (!el) continue;
			const m = maxOf(s, v);
			el.max = m;
			const raw = typeof v[s.key] === "number" ? v[s.key] : 0;
			el.value = Math.min(Math.max(0, raw), m);
			if (lab) lab.textContent = Math.round(raw);
		}
		const moneyEl = document.getElementById("dol-money");
		const moneyLab = document.getElementById("dol-money-val");
		const moneyNum = document.getElementById("dol-money-num");
		if (moneyEl && typeof v.money === "number") {
			const pounds = Math.floor(v.money / 100);
			moneyEl.value = Math.min(Number(moneyEl.max), Math.max(0, pounds));
			if (moneyLab) moneyLab.textContent = "£" + pounds.toLocaleString("en-GB");
			if (moneyNum && document.activeElement !== moneyNum) moneyNum.value = pounds;
		}
		if (status) {
			const locked = v.feats && v.feats.locked ? "LOCKED" : "ok";
			const cheats = v.cheatsEnabled ? "ON" : "off";
			status.textContent = "live | feats: " + locked + " | cheats: " + cheats;
			status.style.color = (v.feats && v.feats.locked) || v.cheatsEnabled ? "#f66" : "#6f6";
		}
		return true;
	};

	const setStat = (key, value) => {
		const v = getV();
		if (!v) {
			syncFromGame();
			return;
		}
		v[key] = Number(value);
		gameRefresh();
		syncFromGame();
	};

	const setMoneyPounds = (pounds) => {
		const v = getV();
		if (!v) {
			syncFromGame();
			return;
		}
		v.money = Math.max(0, Number(pounds) || 0) * 100;
		gameRefresh();
		syncFromGame();
	};

	const root = document.createElement("div");
	root.id = PANEL_ID;
	Object.assign(root.style, {
		position: "fixed",
		top: "12px",
		right: "12px",
		zIndex: "2147483647",
		width: "300px",
		maxHeight: "90vh",
		overflow: "auto",
		background: "rgba(18,18,22,0.94)",
		color: "#eee",
		font: "13px/1.35 system-ui,Segoe UI,sans-serif",
		border: "1px solid #555",
		borderRadius: "10px",
		boxShadow: "0 8px 28px rgba(0,0,0,.45)",
		padding: "10px 12px 12px",
		userSelect: "none",
	});

	const head = document.createElement("div");
	Object.assign(head.style, {
		display: "flex",
		justifyContent: "space-between",
		alignItems: "center",
		marginBottom: "8px",
		cursor: "move",
		fontWeight: "700",
	});
	head.innerHTML =
		'<span>DoL Stats <small style="font-weight:400;opacity:.7">(no feats lock)</small></span>';
	const closeBtn = document.createElement("button");
	closeBtn.textContent = "X";
	Object.assign(closeBtn.style, {
		background: "transparent",
		border: "none",
		color: "#ccc",
		fontSize: "16px",
		cursor: "pointer",
	});
	head.appendChild(closeBtn);
	root.appendChild(head);

	const status = document.createElement("div");
	status.id = "dol-status";
	status.style.cssText = "font-size:11px;margin-bottom:8px;opacity:.9";
	root.appendChild(status);

	const btnRow = document.createElement("div");
	btnRow.style.cssText = "display:flex;gap:6px;margin-bottom:10px;flex-wrap:wrap";

	const mkBtn = (label, fn, title) => {
		const b = document.createElement("button");
		b.textContent = label;
		b.title = title || "";
		Object.assign(b.style, {
			flex: "1",
			minWidth: "90px",
			padding: "6px 8px",
			borderRadius: "6px",
			border: "1px solid #666",
			background: "#2a2a32",
			color: "#eee",
			cursor: "pointer",
		});
		b.onmouseenter = () => (b.style.background = "#3a3a48");
		b.onmouseleave = () => (b.style.background = "#2a2a32");
		b.onclick = fn;
		return b;
	};

	/** Re-bind to current V + refresh sliders (fixes post time-pass freeze) */
	const reconnect = () => {
		const ok = syncFromGame();
		if (ok) {
			// Ensure panel still on top of DOM after heavy re-renders
			if (!document.body.contains(root)) document.body.appendChild(root);
			console.log("[DoL Panel] Reconnected to live State.variables");
		} else {
			console.warn("[DoL Panel] Reconnect failed — no V yet");
		}
	};

	btnRow.append(
		mkBtn("Reconnect", reconnect, "Re-grab live variables after time passes / if sliders feel dead"),
		mkBtn("Sync UI", () => {
			gameRefresh();
			syncFromGame();
		}, "Push clamp + sidebar redraw, then re-read values")
	);
	root.appendChild(btnRow);

	// Money
	{
		const row = document.createElement("div");
		row.style.marginBottom = "10px";
		row.innerHTML =
			'<div style="display:flex;justify-content:space-between"><b>Money</b><span id="dol-money-val"></span></div>';
		const input = document.createElement("input");
		input.id = "dol-money";
		input.type = "range";
		input.min = 0;
		input.max = 1000000;
		input.step = 100;
		input.style.width = "100%";
		input.oninput = () => {
			const v = getV();
			if (!v) return reconnect();
			v.money = Number(input.value) * 100;
			const moneyLab = document.getElementById("dol-money-val");
			if (moneyLab)
				moneyLab.textContent =
					"£" + Math.floor(v.money / 100).toLocaleString("en-GB");
			const moneyNum = document.getElementById("dol-money-num");
			if (moneyNum) moneyNum.value = Math.floor(v.money / 100);
		};
		input.onchange = () => setMoneyPounds(input.value);
		const num = document.createElement("input");
		num.id = "dol-money-num";
		num.type = "number";
		num.min = 0;
		num.step = 100;
		num.placeholder = "£ exact";
		num.style.cssText =
			"width:100%;margin-top:4px;box-sizing:border-box;background:#111;color:#eee;border:1px solid #555;border-radius:4px;padding:4px";
		num.onchange = () => setMoneyPounds(num.value);
		row.append(input, num);
		root.appendChild(row);
	}

	const stateHead = document.createElement("div");
	stateHead.textContent = "State";
	stateHead.style.cssText = "font-weight:700;color:#d4a017;margin:4px 0 6px";
	root.appendChild(stateHead);

	for (const s of STATE) {
		const row = document.createElement("div");
		row.style.marginBottom = "8px";
		const top = document.createElement("div");
		top.style.cssText = "display:flex;justify-content:space-between";
		top.innerHTML =
			"<span>" + s.label + '</span><span id="dol-val-' + s.key + '">0</span>';
		const sl = document.createElement("input");
		sl.type = "range";
		sl.id = "dol-sl-" + s.key;
		sl.min = 0;
		sl.step = 1;
		sl.style.width = "100%";
		// Live write every input using FRESH getV() — not a cached snapshot
		sl.oninput = () => {
			const v = getV();
			if (!v) return reconnect();
			v[s.key] = Number(sl.value);
			const lab = document.getElementById("dol-val-" + s.key);
			if (lab) lab.textContent = Math.round(v[s.key]);
		};
		sl.onchange = () => setStat(s.key, sl.value);
		row.append(top, sl);
		root.appendChild(row);
	}

	const foot = document.createElement("div");
	foot.style.cssText = "font-size:10px;opacity:.65;margin-top:6px";
	foot.textContent =
		"Auto-reconnects after each passage. If a slider feels dead, hit Reconnect. Never enable in-game Cheat mode.";
	root.appendChild(foot);

	// Drag
	let drag = null;
	const onMouseMove = (e) => {
		if (!drag) return;
		root.style.left = e.clientX - drag.x + "px";
		root.style.top = e.clientY - drag.y + "px";
		root.style.right = "auto";
	};
	const onMouseUp = () => {
		drag = null;
	};
	head.addEventListener("mousedown", (e) => {
		if (e.target === closeBtn) return;
		drag = { x: e.clientX - root.offsetLeft, y: e.clientY - root.offsetTop };
	});
	window.addEventListener("mousemove", onMouseMove);
	window.addEventListener("mouseup", onMouseUp);

	// Auto re-sync when the game advances (time pass, links, etc.)
	const onPassage = () => {
		// Defer one tick so State.variables is the new moment
		setTimeout(reconnect, 0);
	};
	const $doc = window.jQuery ? window.jQuery(document) : null;
	if ($doc) {
		$doc.on(":passagerender.dolStatPanel :passagedisplay.dolStatPanel", onPassage);
	}
	// Fallback polling if events miss (every 2s, cheap)
	const poll = setInterval(() => {
		if (!document.getElementById(PANEL_ID)) {
			clearInterval(poll);
			return;
		}
		// Only refresh labels if still connected; don't fight active dragging
		if (document.activeElement && document.activeElement.tagName === "INPUT") return;
		syncFromGame();
	}, 2000);

	const removeAll = () => {
		if ($doc) $doc.off(".dolStatPanel");
		clearInterval(poll);
		window.removeEventListener("mousemove", onMouseMove);
		window.removeEventListener("mouseup", onMouseUp);
		root.remove();
		delete window.__dolStatPanel;
		delete window.__dolStatPanelRemove;
	};

	closeBtn.onclick = removeAll;
	window.__dolStatPanelRemove = removeAll;
	window.__dolStatPanel = root;
	window.__dolStatPanelReconnect = reconnect;

	document.body.appendChild(root);
	reconnect();
	console.log(
		"[DoL Panel] Ready (live rebind). Money is pence under the hood. Use Reconnect if needed; auto-sync after passages."
	);
})();
