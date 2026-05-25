---
title: 業績
permalink: /publications/
---

<section class="page-header">
  <p class="eyebrow">Publications</p>
  <h1>研究業績</h1>
  <p>主要な論文、発表、受賞を掲載します。</p>
</section>

<section class="section">
  <div class="publication-search" data-publication-search>
    <label class="publication-search__label" for="publication-search-input">業績を検索</label>
    <input id="publication-search-input" class="publication-search__input" type="search" placeholder="タイトル、著者、掲載先、年、種別で検索" autocomplete="off" data-publication-search-input>
    <p class="publication-search__status" aria-live="polite" data-publication-search-status></p>
  </div>

  <ol class="publication-list" data-publication-list>
    {% for pub in site.data.publications %}
      {% capture publication_type %}
        {% if pub.entry_type == 'techreport' %}
          技術報告
        {% elsif pub.entry_type == 'inproceedings' %}
          会議録
        {% elsif pub.entry_type == 'article' or pub.entry_type == 'journal' %}
          雑誌論文
        {% elsif pub.entry_type == 'award' %}
          受賞
        {% endif %}
      {% endcapture %}
      <li{% if pub.id %} id="{{ pub.id }}"{% endif %} data-publication-item data-search-text="{{ pub.year | append: ' ' | append: publication_type | append: ' ' | append: pub.title | append: ' ' | append: pub.authors | append: ' ' | append: pub.publisher | strip_html | normalize_whitespace | escape }}">
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
</section>

<script>
  (() => {
    const search = document.querySelector("[data-publication-search]");
    const input = document.querySelector("[data-publication-search-input]");
    const status = document.querySelector("[data-publication-search-status]");
    const items = Array.from(document.querySelectorAll("[data-publication-item]"));

    if (!search || !input || !status || items.length === 0) {
      return;
    }

    search.classList.add("publication-search--ready");

    const normalize = (value) => value.toLowerCase().replace(/\s+/g, " ").trim();
    const total = items.length;

    const update = () => {
      const terms = normalize(input.value).split(" ").filter(Boolean);
      let visible = 0;

      items.forEach((item) => {
        const text = normalize(item.dataset.searchText || item.textContent || "");
        const matches = terms.every((term) => text.includes(term));
        item.hidden = !matches;
        if (matches) {
          visible += 1;
        }
      });

      status.textContent = terms.length === 0
        ? `${total}件の業績を表示しています。`
        : `${visible} / ${total}件の業績が見つかりました。`;
    };

    input.addEventListener("input", update);
    update();
  })();
</script>
