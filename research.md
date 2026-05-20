---
title: 研究
permalink: /research/
---

<section class="page-header">
  <p class="eyebrow">Research</p>
  <h1>研究内容</h1>
</section>

<section class="section">
  <div class="stack">
    {% for item in site.data.research %}
      <article class="research-block" id="{{ item.id }}">
        <div>
          <p class="eyebrow">{{ item.area }}</p>
          <h2>{{ item.title }}</h2>
        </div>
        <p>{{ item.description }}</p>
        <ul class="tag-list">
          {% for tag in item.tags %}
            <li>{{ tag }}</li>
          {% endfor %}
        </ul>
      </article>
    {% endfor %}
  </div>
</section>
