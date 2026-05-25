"use strict";

const { SearchService } = ChromeUtils.importESModule(
  "moz-src:///toolkit/components/search/SearchService.sys.mjs"
);

const form = document.getElementById("search-form");
const input = document.getElementById("search-input");

async function getCurrentSearchEngine() {
  try {
    return await SearchService.getDefault();
  } catch (error) {
    console.error("Unable to load the default search engine.", error);
    return null;
  }
}

async function updateSearchLabel() {
  const engine = await getCurrentSearchEngine();
  input.placeholder = engine ? `Search with ${engine.name}` : "Search the web";
}

form.addEventListener("submit", async event => {
  event.preventDefault();

  const query = input.value.trim();
  if (!query) {
    input.focus();
    return;
  }

  const engine = await getCurrentSearchEngine();
  const submission = engine?.getSubmission(query);
  const url = submission?.uri?.spec;

  if (url) {
    window.location.assign(url);
  }
});

updateSearchLabel();
