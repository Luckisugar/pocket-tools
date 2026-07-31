/**
 * DoL Stat Panel — console cheat UI without enabling official cheats.
 * Does NOT set V.cheatsEnabled or V.feats.locked (feats stay earnable).
 *
 * Usage: open the game, load a save, F12 → Console → paste this whole file → Enter.
 * Prefer: open START-HERE-Stat-Panel.html → Copy → paste into game console.
 *
 * Close: click X, or run: window.__dolStatPanelRemove && window.__dolStatPanelRemove()
 */
(() => {
	const PANEL_ID = "dol-stat-panel";

	const getV = () => {
		if (typeof V !== "undefined" && V != null && typeof V.money === "number") return V;
		try {
			const vars = window.SugarCube && window.SugarCube.State && window.SugarCube.State.variables;
			if (vars && typeof vars.money === "number") return vars;
		} catch (_) {}
		return null;
	};

	const getSetup = () => {
		try {
			if (typeof setup !== "undefined" && setup) return setup;
			if (window.SugarCube && window.SugarCube.setup) return window.SugarCube.setup;
		} catch (_) {}
		return null;
	};

	if (!getV()) {
		console.error("[DoL Panel] No game state. Load a save first, then re-paste.");
		return;
	}

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

	const CRIME_FALLBACK = {
		assault: "Assault",
		coercion: "Coercion",
		destruction: "Destruction of property",
		exposure: "Indecent exposure",
		obstruction: "Obstruction of justice",
		prostitution: "Prostitution",
		resisting: "Resisting arrest",
		thievery: "Thievery",
		petty: "Petty thievery",
		trespassing: "Trespassing",
	};

	const titleCase = (s) =>
		String(s || "")
			.split(" ")
			.map((w) => (w ? w.charAt(0).toUpperCase() + w.slice(1) : w))
			.join(" ");

	const crimeList = () => {
		const s = getSetup();
		const names = (s && s.crimeNames) || CRIME_FALLBACK;
		return Object.keys(names).map((key) => ({
			key,
			label: titleCase(names[key] || CRIME_FALLBACK[key] || key),
		}));
	};

	const crimeMax = () => {
		try {
			if (typeof C !== "undefined" && C.crime && typeof C.crime.max === "number") return C.crime.max;
		} catch (_) {}
		return 10000;
	};

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

	const ensureCrimeSliders = () => {
		const body = document.getElementById("dol-crime-body");
		if (!body) return;
		const list = crimeList();
		const existing = new Set(
			[...body.querySelectorAll("[data-crime-key]")].map((el) => el.getAttribute("data-crime-key"))
		);
		// If keys mismatch (first paint / update), rebuild
		const want = list.map((c) => c.key).join(",");
		if (body.dataset.keys === want) return;
		body.dataset.keys = want;
		body.innerHTML = "";

		const zeroRow = document.createElement("div");
		zeroRow.style.cssText = "display:flex;gap:6px;margin-bottom:8px;flex-wrap:wrap";
		const zeroBtn = document.createElement("button");
		zeroBtn.textContent = "Zero all crime";
		zeroBtn.title = "Set every crime.current (and daily) to 0";
		Object.assign(zeroBtn.style, {
			flex: "1",
			padding: "6px 8px",
			borderRadius: "6px",
			border: "1px solid #666",
			background: "#2a2a32",
			color: "#eee",
			cursor: "pointer",
		});
		zeroBtn.onclick = () => {
			const v = getV();
			if (!v || !v.crime) return reconnect();
			for (const c of list) {
				if (!v.crime[c.key]) continue;
				v.crime[c.key].current = 0;
				if (typeof v.crime[c.key].daily === "number") v.crime[c.key].daily = 0;
			}
			gameRefresh();
			syncFromGame();
		};
		zeroRow.appendChild(zeroBtn);
		body.appendChild(zeroRow);

		for (const c of list) {
			const row = document.createElement("div");
			row.style.marginBottom = "8px";
			row.setAttribute("data-crime-key", c.key);
			const top = document.createElement("div");
			top.style.cssText = "display:flex;justify-content:space-between";
			top.innerHTML =
				"<span>" +
				c.label +
				'</span><span id="dol-crime-val-' +
				c.key +
				'">0</span>';
			const sl = document.createElement("input");
			sl.type = "range";
			sl.id = "dol-crime-sl-" + c.key;
			sl.min = 0;
			sl.max = crimeMax();
			sl.step = 10;
			sl.style.width = "100%";
			sl.oninput = () => {
				const v = getV();
				if (!v || !v.crime || !v.crime[c.key]) return reconnect();
				v.crime[c.key].current = Number(sl.value);
				const lab = document.getElementById("dol-crime-val-" + c.key);
				if (lab) lab.textContent = Math.round(v.crime[c.key].current);
			};
			sl.onchange = () => {
				const v = getV();
				if (!v || !v.crime || !v.crime[c.key]) return reconnect();
				v.crime[c.key].current = Number(sl.value);
				// keep count consistent with official setter rules
				if (v.crime[c.key].current === 0) v.crime[c.key].count = 0;
				else if (!v.crime[c.key].count) v.crime[c.key].count = 1;
				gameRefresh();
				syncFromGame();
			};
			row.append(top, sl);
			body.appendChild(row);
		}
	};

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

		ensureCrimeSliders();

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

		// Infinite pepper spray
		const sprayBtn = document.getElementById("dol-spray-btn");
		if (sprayBtn) {
			const on = !!v.infinitespray;
			sprayBtn.textContent = on ? "Infinite spray: ON" : "Infinite spray: OFF";
			sprayBtn.style.borderColor = on ? "#6a6" : "#666";
			sprayBtn.style.color = on ? "#9f9" : "#eee";
		}

		// Crime
		const cmax = crimeMax();
		for (const c of crimeList()) {
			const el = document.getElementById("dol-crime-sl-" + c.key);
			const lab = document.getElementById("dol-crime-val-" + c.key);
			if (!el || !v.crime || !v.crime[c.key]) continue;
			el.max = cmax;
			const raw = typeof v.crime[c.key].current === "number" ? v.crime[c.key].current : 0;
			el.value = Math.min(Math.max(0, raw), cmax);
			if (lab) lab.textContent = Math.round(raw);
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

	const mkBtn = (label, fn, title, id) => {
		const b = document.createElement("button");
		b.textContent = label;
		if (id) b.id = id;
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
		b.onmouseenter = () => {
			if (!b.dataset.lockedHover) b.style.background = "#3a3a48";
		};
		b.onmouseleave = () => {
			if (!b.dataset.lockedHover) b.style.background = "#2a2a32";
		};
		b.onclick = fn;
		return b;
	};

	const reconnect = () => {
		const ok = syncFromGame();
		if (ok) {
			if (!document.body.contains(root)) document.body.appendChild(root);
			console.log("[DoL Panel] Reconnected to live State.variables");
		} else {
			console.warn("[DoL Panel] Reconnect failed — no V yet");
		}
	};

	btnRow.append(
		mkBtn(
			"Reconnect",
			reconnect,
			"Re-grab live variables after time passes / if sliders feel dead"
		),
		mkBtn(
			"Sync UI",
			() => {
				gameRefresh();
				syncFromGame();
			},
			"Push clamp + sidebar redraw, then re-read values"
		)
	);
	root.appendChild(btnRow);

	// Money + infinite spray
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

		const sprayBtn = mkBtn(
			"Infinite spray: OFF",
			() => {
				const v = getV();
				if (!v) return reconnect();
				// Match in-game cheat: on → spray 5 + flag; off → clear flag
				if (v.infinitespray) {
					v.infinitespray = 0;
				} else {
					try {
						if (typeof Wikifier !== "undefined") Wikifier.wikifyEval("<<spray 5>>");
					} catch (_) {}
					v.infinitespray = 1;
				}
				syncFromGame();
			},
			"Same as cheat menu Infinite spray — does not enable official cheats",
			"dol-spray-btn"
		);
		sprayBtn.style.marginTop = "8px";
		sprayBtn.style.width = "100%";
		sprayBtn.style.flex = "none";

		row.append(input, num, sprayBtn);
		root.appendChild(row);
	}

	// State section
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

	// --- Crime: collapsible / dockable section ---
	const crimeWrap = document.createElement("div");
	crimeWrap.style.cssText = "margin-top:10px;border-top:1px solid #444;padding-top:8px";

	const crimeToggle = document.createElement("button");
	crimeToggle.type = "button";
	crimeToggle.id = "dol-crime-toggle";
	crimeToggle.setAttribute("aria-expanded", "false");
	Object.assign(crimeToggle.style, {
		width: "100%",
		display: "flex",
		justifyContent: "space-between",
		alignItems: "center",
		padding: "8px 10px",
		borderRadius: "6px",
		border: "1px solid #666",
		background: "#252530",
		color: "#eee",
		cursor: "pointer",
		font: "inherit",
		fontWeight: "700",
	});
	const crimeToggleLabel = document.createElement("span");
	crimeToggleLabel.innerHTML = 'Crime <small style="font-weight:400;opacity:.7">(dock)</small>';
	const crimeChevron = document.createElement("span");
	crimeChevron.id = "dol-crime-chevron";
	crimeChevron.textContent = "▸";
	crimeToggle.append(crimeToggleLabel, crimeChevron);

	const crimeBody = document.createElement("div");
	crimeBody.id = "dol-crime-body";
	crimeBody.style.cssText = "display:none;margin-top:10px";

	const setCrimeOpen = (open) => {
		crimeBody.style.display = open ? "block" : "none";
		crimeToggle.setAttribute("aria-expanded", open ? "true" : "false");
		crimeChevron.textContent = open ? "▾" : "▸";
		crimeToggle.style.borderColor = open ? "#8a6" : "#666";
		if (open) syncFromGame();
	};

	crimeToggle.onclick = () => {
		const open = crimeToggle.getAttribute("aria-expanded") !== "true";
		setCrimeOpen(open);
	};

	crimeWrap.append(crimeToggle, crimeBody);
	root.appendChild(crimeWrap);

	const foot = document.createElement("div");
	foot.style.cssText = "font-size:10px;opacity:.65;margin-top:8px";
	foot.textContent =
		"Crime starts collapsed. Spray can still raise crime in-combat — zero it under Crime. Never enable in-game Cheat mode.";
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

	const onPassage = () => {
		setTimeout(reconnect, 0);
	};
	const $doc = window.jQuery ? window.jQuery(document) : null;
	if ($doc) {
		$doc.on(":passagerender.dolStatPanel :passagedisplay.dolStatPanel", onPassage);
	}
	const poll = setInterval(() => {
		if (!document.getElementById(PANEL_ID)) {
			clearInterval(poll);
			return;
		}
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
		delete window.__dolStatPanelReconnect;
	};

	closeBtn.onclick = removeAll;
	window.__dolStatPanelRemove = removeAll;
	window.__dolStatPanel = root;
	window.__dolStatPanelReconnect = reconnect;

	document.body.appendChild(root);
	reconnect();
	console.log(
		"[DoL Panel] Ready. Crime section is collapsible. Infinite spray toggle included. Live rebind on."
	);
})();
