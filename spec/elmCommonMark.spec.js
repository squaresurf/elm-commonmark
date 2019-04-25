const fs = require("fs");
const puppeteer = require("puppeteer");

const specBuffer = fs.readFileSync("spec/CommonMark-0.29.0.spec.json");
const jsonSpec = JSON.parse(specBuffer);

let browser;
let page;

const textarea_id = "markdown_input";

beforeAll(async () => {
  browser = await puppeteer.launch();
  page = await browser.newPage();
  await page.goto("http://localhost:8000/src/Main.elm");
});

afterEach(async () => {
  await page.evaluate(id => {
    document.getElementById(id).value = "";
  }, textarea_id);
});

afterAll(async () => {
  await browser.close();
});

let i = 0;
for (i; i < jsonSpec.length; i++) {
  (i => {
    let ex = jsonSpec[i];
    let testName = `#${ex.example} ${ex.section}: ${ex.start_line}-${
      ex.end_line
    }`;

    test(testName, async () => {
      await page.focus("#markdown_input");
      await page.keyboard.type(ex.markdown);

      const element = await page.$("#parsed_markdown");
      const html = await page.evaluate(element => element.innerHTML, element);
      expect(`${html}\n`).toBe(ex.html);
    });
  })(i);
}
