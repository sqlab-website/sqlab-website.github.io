---
title: 業績
permalink: /publications/
---

<section class="page-header">
  <p class="eyebrow">Publications</p>
  <h1>研究業績</h1>
  <p>主要な論文、発表、受賞を掲載します。(作成中)</p>
</section>

<section class="section">
  <div class="publication-search" data-publication-search>
    <div class="publication-search__controls">
      <label class="publication-search__field">
        <span class="publication-search__label">種別</span>
        <select class="publication-search__select" data-publication-type-filter>
          <option value="all">すべて</option>
          <option value="journal">雑誌論文</option>
          <option value="proceedings">会議予稿</option>
          <option value="techreport">技術報告</option>
        </select>
      </label>
      <label class="publication-search__field">
        <span class="publication-search__label">業績を検索</span>
        <input id="publication-search-input" class="publication-search__input" type="search" placeholder="タイトル、著者、掲載先、年で検索" autocomplete="off" data-publication-search-input>
      </label>
    </div>
    <p class="publication-search__status" aria-live="polite" data-publication-search-status></p>
  </div>

  <ol class="publication-list" data-publication-list>
    {% for pub in site.data.publications %}
      {% capture publication_type %}
        {% if pub.entry_type == 'techreport' %}
          技術報告
        {% elsif pub.entry_type == 'inproceedings' %}
          会議予稿
        {% elsif pub.entry_type == 'article' or pub.entry_type == 'journal' %}
          雑誌論文
        {% elsif pub.entry_type == 'award' %}
          受賞
        {% elsif pub.entry_type == 'poster' %}
          ポスター
        {% endif %}
      {% endcapture %}
      {% capture publication_type_key %}
        {% if pub.entry_type == 'techreport' %}
          techreport
        {% elsif pub.entry_type == 'inproceedings' %}
          proceedings
        {% elsif pub.entry_type == 'article' or pub.entry_type == 'journal' %}
          journal
        {% elsif pub.entry_type == 'award' %}
          award
        {% elsif pub.entry_type == 'poster' %}
          poster
        {% endif %}
      {% endcapture %}
      <li{% if pub.id %} id="{{ pub.id }}"{% endif %} data-publication-item data-publication-type="{{ publication_type_key | strip }}" data-search-text="{{ pub.year | append: ' ' | append: publication_type | append: ' ' | append: pub.title | append: ' ' | append: pub.authors | append: ' ' | append: pub.publisher | strip_html | normalize_whitespace | escape }}">
        <div class="publication-list__meta">
          <span class="publication-list__year">{{ pub.year }}</span>
          {% assign publication_type_label = publication_type | strip %}
          {% if publication_type_label != '' %}
            <span class="publication-list__type">{{ publication_type_label }}</span>
          {% endif %}
        </div>
        <div class="publication-list__title">
          {% if pub.doi %}
            {% assign doi_url = pub.doi %}
            {% unless doi_url contains '://' %}
              {% assign doi_url = pub.doi | prepend: 'https://doi.org/' %}
            {% endunless %}
            <strong><a href="{{ doi_url }}">{{ pub.title }}</a></strong>
          {% else %}
            <strong>{{ pub.title }}</strong>
          {% endif %}
          {% if pub.bibtex_url and pub.entry_type != 'award' %}
            <a class="publication-list__bibtex" href="{{ pub.bibtex_url | relative_url }}" aria-label="{{ pub.title }} のBibTeXを開く" title="BibTeX">BibTeX</a>
          {% endif %}
        </div>
        <p>
          {{ pub.authors }}<br>
          {{ pub.publisher }}
        </p>
      </li>
    {% endfor %}
  </ol>
  <div class="publication-download">
    <button class="button publication-search__download" type="button" data-publication-bibtex-download>表示中のBibTeXをダウンロード</button>
    <p class="publication-search__status" aria-live="polite" data-publication-bibtex-status></p>
  </div>
</section>

<script>
  (() => {
    const search = document.querySelector("[data-publication-search]");
    const typeFilter = document.querySelector("[data-publication-type-filter]");
    const input = document.querySelector("[data-publication-search-input]");
    const status = document.querySelector("[data-publication-search-status]");
    const downloadButton = document.querySelector("[data-publication-bibtex-download]");
    const downloadStatus = document.querySelector("[data-publication-bibtex-status]");
    const items = Array.from(document.querySelectorAll("[data-publication-item]"));

    if (!search || !typeFilter || !input || !status || !downloadButton || !downloadStatus || items.length === 0) {
      return;
    }

    search.classList.add("publication-search--ready");

    const normalize = (value) => value.toLowerCase().replace(/\s+/g, " ").trim();
    const total = items.length;

    const update = () => {
      const selectedType = typeFilter.value;
      const terms = normalize(input.value).split(" ").filter(Boolean);
      let visible = 0;

      items.forEach((item) => {
        const text = normalize(item.dataset.searchText || item.textContent || "");
        const typeMatches = selectedType === "all" || item.dataset.publicationType === selectedType;
        const textMatches = terms.every((term) => text.includes(term));
        const matches = typeMatches && textMatches;
        item.hidden = !matches;
        if (matches) {
          visible += 1;
        }
      });

      status.textContent = terms.length === 0
        ? `${visible} / ${total}件の業績を表示しています。`
        : `${visible} / ${total}件の業績が見つかりました。`;

      const visibleBibtexCount = items.filter((item) => !item.hidden && item.querySelector(".publication-list__bibtex")).length;
      downloadButton.disabled = visibleBibtexCount === 0;
      downloadStatus.textContent = visibleBibtexCount === 0 ? "表示中の項目にBibTeXはありません。" : "";
    };

    const bibtexEntryFrom = async (url) => {
      const response = await fetch(url);
      if (!response.ok) {
        throw new Error(`${response.status} ${url}`);
      }
      const html = await response.text();
      const doc = new DOMParser().parseFromString(html, "text/html");
      return doc.querySelector(".bibtex-entry code")?.textContent.trim() || "";
    };

    const downloadVisibleBibtex = async () => {
      const links = items
        .filter((item) => !item.hidden)
        .map((item) => item.querySelector(".publication-list__bibtex"))
        .filter(Boolean);

      if (links.length === 0) {
        downloadStatus.textContent = "表示中の項目にBibTeXはありません。";
        return;
      }

      downloadButton.disabled = true;
      downloadStatus.textContent = `${links.length}件のBibTeXを作成しています。`;

      try {
        const entries = (await Promise.all(links.map((link) => bibtexEntryFrom(link.href)))).filter(Boolean);
        if (entries.length === 0) {
          downloadStatus.textContent = "ダウンロードできるBibTeXがありません。";
          return;
        }

        const blob = new Blob([`${entries.join("\n\n")}\n`], { type: "application/x-bibtex;charset=utf-8" });
        const url = URL.createObjectURL(blob);
        const anchor = document.createElement("a");
        anchor.href = url;
        anchor.download = "sqlab-publications.bib";
        document.body.append(anchor);
        anchor.click();
        anchor.remove();
        URL.revokeObjectURL(url);
        downloadStatus.textContent = `${entries.length}件のBibTeXをダウンロードしました。`;
      } catch (error) {
        downloadStatus.textContent = "BibTeXの作成に失敗しました。";
        console.error(error);
      } finally {
        downloadButton.disabled = false;
      }
    };

    downloadButton.addEventListener("click", downloadVisibleBibtex);
    typeFilter.addEventListener("change", update);
    input.addEventListener("input", update);
    update();
  })();
</script>
